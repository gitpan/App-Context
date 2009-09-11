#############################################################################
## $Id: ClusterNode.pm 3666 2006-03-11 20:34:10Z spadkins $
#############################################################################

package App::Context::POE::ClusterNode;
$VERSION = (q$Revision: 3666 $ =~ /(\d[\d\.]*)/)[0];  # VERSION numbers generated by svn

use App;
use App::Context::POE::Server;

@ISA = ( "App::Context::POE::Server" );

use strict;

use Date::Format;

use POE;
use POE::Component::IKC::Client;
use POE::Component::IKC::Responder;
use POE::Component::Server::SimpleHTTP;
use HTTP::Status qw/RC_OK/;
use Socket qw(INADDR_ANY);

=head1 NAME

App::Context::ClusterNode - a runtime environment for a Cluster Node that serves a Cluster Controller

=head1 SYNOPSIS

   # ... official way to get a Context object ...
   use App;
   $context = App->context();
   $config = $context->config();   # get the configuration
   $config->dispatch_events();     # dispatch events

   # ... alternative way (used internally) ...
   use App::Context::ClusterNode;
   $context = App::Context::ClusterNode->new();

=cut

sub _init2a {
    &App::sub_entry if ($App::trace);
    my ($self, $options) = @_;
    $self->{controller_host} = $options->{controller_host};
    $self->{controller_port} = $options->{controller_port};
    $self->{disable_event_loop_extensions} = 1;
    die "Node must have a controller host and port defined (\$context->{options}{controller_host} and {controller_port})"
        if (!$self->{controller_host} || !$self->{controller_port});

    push(@{$self->{poe_states}}, qw(poe_cancel_async_event));
    push(@{$self->{poe_ikc_published_states}}, qw(poe_cancel_async_event));

    $self->_init_poe($options);

    &App::sub_exit() if ($App::trace);
}

sub _init_poe {
    &App::sub_entry if ($App::trace);
    my ($self, $options) = @_;

    my $ikc_name = "poe_$self->{host}_$self->{port}";
    ### Set up a server
    POE::Component::IKC::Responder->spawn();
    POE::Component::IKC::Client->spawn(
        ip      => $self->{controller_host},
        port    => $self->{controller_port},
        name    => $ikc_name,
        timeout => 60,
    );
    $self->log({level=>3},"Listening for Inter-Kernel Communications on $self->{host}:$self->{port}\n") if $self->{options}{poe_ikc_debug};

    my $session_name = $self->{poe_session_name};
    POE::Component::Server::SimpleHTTP->new(
        'ALIAS'    => $self->{poe_kernel_http_name},
        'ADDRESS'  => INADDR_ANY,
        'PORT'     => $self->{options}{http_port},
        'HANDLERS' => [
            { 'DIR' => '/testrun', 'SESSION' => $session_name, 'EVENT' => 'poe_http_test_run', },
            { 'DIR' => '.*', 'SESSION' => $session_name, 'EVENT' => 'poe_http_server_state', },
        ],
    );
    $self->log({level=>3},"Listening for HTTP Requests on $self->{host}:$self->{options}{http_port}\n") if $self->{options}{poe_http_debug};

    &App::sub_exit() if ($App::trace);
}

sub _init2b {
    &App::sub_entry if ($App::trace);
    my ($self, $options) = @_;

    &App::sub_exit() if ($App::trace);
}

sub _start {
    &App::sub_entry if ($App::trace);
    my ( $self, $kernel, $heap ) = @_[ OBJECT, KERNEL, HEAP ];

    my $name = $self->{poe_session_name};
    $kernel->alias_set($name);

    $kernel->sig(CHLD => "poe_sigchld");
    $kernel->sig(HUP  => "poe_sigignore");
    $kernel->sig(INT  => "poe_sigterm");
    $kernel->sig(QUIT => "poe_sigterm");
    $kernel->sig(USR1 => "poe_sigignore");
    $kernel->sig(USR2 => "poe_sigignore");
    $kernel->sig(TERM => "poe_sigterm");

    $kernel->call( IKC => publish => $name, $self->{poe_ikc_published_states} );

    my $remote_server_name = "poe_$self->{controller_host}_$self->{controller_port}";
    my $node               = "$self->{host}:$self->{port}";

    $kernel->post("IKC", "monitor", "poe://$remote_server_name",
        {register   => "ikc_register",
         unregister => "ikc_unregister",
         shutdown   => "ikc_shutdown",
         data       => $node});

    # don't start kicking off async events until we give the nodes a chance to register themselves
    $kernel->delay_set("poe_event_loop_extension", 5) if (!$self->{disable_event_loop_extensions});
    $kernel->delay_set("poe_alarm", 5);

    &App::sub_exit() if ($App::trace);
}

sub ikc_register {
    &App::sub_entry if ($App::trace);
    my ($self, $kernel, $remote_kernel_id, $node) = @_[OBJECT, KERNEL, ARG0, ARG3];
    $self->log({level=>3},"ikc_register: ($remote_kernel_id; node=$node)\n") if $self->{options}{poe_ikc_debug};
    $self->{controller_up} = 1;
    $self->send_node_status();
    &App::sub_exit() if ($App::trace);
    return();
}

sub ikc_unregister {
    &App::sub_entry if ($App::trace);
    my ($self, $kernel, $remote_kernel_id, $session_name, $node) = @_[OBJECT, KERNEL, ARG0, ARG1, ARG3];
    $self->log({level=>3},"ikc_unregister: ($remote_kernel_id; session_name=$session_name; node=$node)\n") if $self->{options}{poe_ikc_debug};
    $self->{controller_up} = 0;
    $kernel->yield("poe_shutdown");
    &App::sub_exit() if ($App::trace);
}

sub ikc_shutdown {
    &App::sub_entry if ($App::trace);
    my ( $self, $kernel, $session, $heap ) = @_[ OBJECT, KERNEL, SESSION, HEAP ];
    $self->log({level=>3},"ikc_shutdown\n") if $self->{options}{poe_ikc_debug};
    &App::sub_exit() if ($App::trace);
    return;
}

sub dispatch_events_begin {
    &App::sub_entry if ($App::trace);
    my ($self) = @_;
    $self->log({level=>3},"Starting Cluster Node on $self->{host}:$self->{port}\n") if $self->{options}{poe_trace};
    my $node_heartbeat  = $self->{options}{node_heartbeat} || 60;
    $self->schedule_event(
        method => "send_node_status",
        time => time(),  # immediately ...
        interval => $node_heartbeat,  # and every X seconds hereafter
    );
    my $node_alarm_interval = $self->{options}{node_alarm_interval} || 5;
    $self->schedule_event(
        method => "alarm_noop",
        #time => time()+5,  # immediately ...
        interval => $node_alarm_interval,  # and every X seconds hereafter
    );
    &App::sub_exit() if ($App::trace);
}

sub dispatch_events_end {
    &App::sub_entry if ($App::trace);
    my ($self) = @_;
    $self->log({level=>3},"Stopping Cluster Node\n") if $self->{options}{poe_trace};
    &App::sub_exit() if ($App::trace);
}

sub send_node_status {
    &App::sub_entry if ($App::trace);
    my ($self) = @_;
    my $controller_host = $self->{controller_host};
    my $controller_port = $self->{controller_port};
    my $node_host       = $self->{host};
    my $node_port       = $self->{port};

    my $remote_server_name = "poe_${controller_host}_${controller_port}";
    my $remote_session_alias = $self->{poe_session_name};  # remote is same as local
    my $remote_session_state = "poe_receive_node_status";
    my $sys_info = $self->get_sys_info();
    my $memfree = $sys_info->{memfree} + $sys_info->{buffers} + $sys_info->{cached};
    my $s_info = {
        load => $sys_info->{load},
        system_load => $sys_info->{load},
        memfree => $memfree,
        memtotal => $sys_info->{memtotal},
        swapfree => $sys_info->{swapfree},
        swaptotal => $sys_info->{swaptotal},
        max_async_events => $self->{max_async_events}
    };

    if ($self->{controller_up}) {
        my $kernel = $self->{poe_kernel};
        $kernel->post("IKC", "post", "poe://$remote_server_name/$remote_session_alias/$remote_session_state",
            [ "$node_host:$node_port", $s_info ]);
    }

    &App::sub_exit() if ($App::trace);
}

sub alarm_noop {
    &App::sub_entry if ($App::trace);
    &App::sub_exit() if ($App::trace);
    return();
}

sub state {
    &App::sub_entry if ($App::trace);
    my ($self) = @_;

    my $datetime = time2str("%Y-%m-%d %H:%M:%S", time());
    my $state = "Cluster Node: Node: $self->{host}:$self->{port}  procs[$self->{num_procs}/$self->{max_procs}:max]  async_events[$self->{num_async_events}/$self->{max_async_events}:max]\n[$datetime]\n";
    $state .= "\n";
    $state .= $self->_state();

    &App::sub_exit($state) if ($App::trace);
    return($state);
}

sub _state {
    &App::sub_entry if ($App::trace);
    my ($self) = @_;

    my $state = "";

    $state .= $self->SUPER::_state();

    &App::sub_exit($state) if ($App::trace);
    return($state);
}

sub poe_cancel_async_event {
    &App::sub_entry if ($App::trace);
    my ( $self, $kernel, $heap, $arg0 ) = @_[ OBJECT, KERNEL, HEAP, ARG0 ];
    $self->profile_start("poe_cancel_async_event") if $self->{poe_profile};
    my ($runtime_event_token) = @$arg0;

    $self->log({level=>3},"poe_cancel_async_event BEGIN runtime_event_token=[$runtime_event_token]\n");
    ### Find if running
    my ($event_token);
    for my $pid (keys %{$self->{running_async_event}}) {
        $event_token = $self->{running_async_event}{$pid}[0]{event_token};
        if ($runtime_event_token eq $event_token) {

            ### Kill it
            if ($pid =~ /^[0-9]+$/) {
                kill(9, $pid);
            }

            ### Remove from pending
            delete $self->{running_async_event}{$pid};
            $self->log({level=>3},"poe_cancel_async_event FOUND RUNNING event_token=[$event_token] pid=[$pid]\n");

            last;
        }
    }

    ### Find if pending
    for (my $i = 0; $i < @{$self->{pending_async_events}}; $i++) {
        $event_token = $self->{pending_async_events}[$i][0]{event_token};
        if ($runtime_event_token eq $event_token) {
            splice(@{$self->{pending_async_events}}, $i, 1);
            $self->log({level=>3},"poe_cancel_async_event FOUND PENDING event_token=[$event_token]\n");
        }
    }
    $self->log({level=>3},"poe_cancel_async_event END   event_token=[$event_token]\n");
    $self->profile_stop("poe_cancel_async_event") if $self->{poe_profile};

    &App::sub_exit() if ($App::trace);
}

1;
