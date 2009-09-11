#############################################################################
## $Id: ClusterController.pm 6785 2006-08-11 23:13:19Z spadkins $
#############################################################################

package App::Context::POE::ClusterController;
$VERSION = (q$Revision: 6785 $ =~ /(\d[\d\.]*)/)[0];  # VERSION numbers generated by svn

use App;
use App::Context::POE::Server;

@ISA = ( "App::Context::POE::Server" );

use Date::Format;
use POE;

use strict;

=head1 NAME

App::Context::POE::ClusterController - a runtime environment of a Cluster Controller served by many Cluster Nodes

=head1 SYNOPSIS

   # ... official way to get a Context object ...
   use App;
   $context = App->context();
   $config = $context->config();   # get the configuration
   $config->dispatch_events();     # dispatch events

   # ... alternative way (used internally) ...
   use App::Context::POE::ClusterController;
   $context = App::Context::POE::ClusterController->new();

=cut

sub _init2a {
    &App::sub_entry if ($App::trace);
    my ($self, $options) = @_;
    die "Controller must have a port defined (\$context->{options}{port})" if (!$self->{port});
    $self->{is_controller}    = 1;
    $self->{num_async_events} = 0;
    $self->{max_async_events_per_node} = $self->{options}{"app.context.max_async_events_per_node"} || 10;
    $self->{max_async_events} = 0;  # start with 0 because there are no nodes up

    push(@{$self->{poe_states}},
        "poe_receive_node_status",
        "poe_run_event");
    push(@{$self->{poe_ikc_published_states}},
        "poe_receive_node_status");

    $self->_init_poe($options);

    &App::sub_exit() if ($App::trace);
}

sub _init2b {
    &App::sub_entry if ($App::trace);
    my ($self, $options) = @_;
    $self->startup_nodes($options) if ($options->{startup});
    &App::sub_exit() if ($App::trace);
}

sub dispatch_events_begin {
    my ($self) = @_;
    $self->log({level=>3},"Starting Cluster Controller on $self->{host}:$self->{port}\n") if $self->{options}{poe_trace};
}

sub dispatch_events_end {
    my ($self) = @_;
    $self->log({level=>3},"Stopping Cluster Controller\n") if $self->{options}{poe_trace};
    # nothing special yet
}

sub send_async_event_now {
    &App::sub_entry if ($App::trace);
    my ($self, $event, $callback_event) = @_;

    my $destination = $event->{destination};
    if (! defined $destination) {
        $self->log({level=>2},"ERROR $event->{name}.$event->{method} : destination not assigned\n");
    }
    elsif ($event->{destination} eq "in_process") {
        my $event_token = $self->send_async_event_in_process($event, $callback_event);
    }
    elsif ($destination =~ /^([^:]+):([0-9]+)$/) {
        my $controller = "$self->{host}:$self->{port}";
        my $node_host = $1;
        my $node_port = $2;
        my $args = $event->{args};

        my $remote_server_name = "poe_${node_host}_${node_port}";
        my $remote_session_alias = $self->{poe_session_name};  # remote is same as local
        my $remote_session_state = "poe_enqueue_async_event";
        my $local_callback_state = "poe_enqueue_async_event_finished";

        $self->{num_async_events}++;
        $self->{node}{$destination}{num_async_events}++;

        my $kernel = $self->{poe_kernel};
        $kernel->post("IKC", "call", "poe://$remote_server_name/$remote_session_alias/$remote_session_state",
            [ $controller, $event, $callback_event ], "poe:$local_callback_state" );
    }
    else {
        $self->SUPER::send_async_event_now($event, $callback_event);
    }
    &App::sub_exit() if ($App::trace);
}

sub ikc_register {
    &App::sub_entry if ($App::trace);
    my ($self, $kernel, $session_name) = @_[OBJECT, KERNEL, ARG1];
    $self->log({level=>3},"ikc_register: ($session_name)\n") if $self->{options}{poe_ikc_debug};
    if ($session_name =~ /^poe_([^_]+)_(\d+)$/) {
        my $node = "$1:$2";
        $self->set_node_up($node);
    }
    my ($retval);
    &App::sub_exit($retval) if ($App::trace);
    return($retval);
}

sub ikc_unregister {
    &App::sub_entry if ($App::trace);
    my ($self, $kernel, $session_name) = @_[OBJECT, KERNEL, ARG1];
    $self->log({level=>3},"ikc_unregister: ($session_name)\n") if $self->{options}{poe_ikc_debug};
    if ($session_name =~ /^poe_([^_]+)_(\d+)$/) {
        my $node = "$1:$2";
        $self->set_node_down($node);
    }
    &App::sub_exit() if ($App::trace);
}

sub ikc_shutdown {
    &App::sub_entry if ($App::trace);
    my ($self, $kernel, $arg0, $arg1, $arg2, $arg3) = @_[OBJECT, KERNEL, ARG0, ARG1, ARG2, ARG3];
    $self->log({level=>3},"ikc_shutdown: args=($arg0, $arg1, $arg2, $arg3)\n") if $self->{options}{poe_ikc_debug};
    &App::sub_exit() if ($App::trace);
    return;
}

# $runtime_event_tokens take the following forms:
#    $runtime_event_token = $pid; -- App::Context::Server::send_async_event_now() and ::finish_pid()
#    $runtime_event_token = "$host-$port-$serial"; -- i.e. a plain event token on the node
sub _abort_running_async_event {
    &App::sub_entry if ($App::trace);
    my ($self, $runtime_event_token, $event, $callback_event) = @_;
    if ($runtime_event_token && $event && $callback_event) {
        if ($runtime_event_token =~ /^[0-9]+$/) {
            kill(9, $runtime_event_token);
        }
        elsif ($runtime_event_token =~ /^([^-]+)-([0-9]+)-/) {
            my $node_host = $1;
            my $node_port = $2;

            my $remote_server_name = "poe_${node_host}_${node_port}";
            my $remote_session_alias = $self->{poe_session_name};  # remote is same as local
            my $remote_session_state = "poe_cancel_async_event";

            my $kernel = $self->{poe_kernel};
            $kernel->post("IKC", "post", "poe://$remote_server_name/$remote_session_alias/$remote_session_state",
                [ $runtime_event_token ]);
        }
        else {
            $self->log({level=>2},"ERROR $event->{name}.$event->{method} : unparseable runtime event token [$runtime_event_token]\n");
        }
    }
    &App::sub_exit() if ($App::trace);
}

sub assign_event_destination {
    &App::sub_entry if ($App::trace);
    my ($self, $event) = @_;
    my $assigned = undef;
    if ($self->{num_async_events} < $self->{max_async_events}) {
        # SPA 2006-07-01: I just commented this out. I shouldn't need it.
        # $event->{destination} = $self->{host};
        my $main_service = $self->{main_service};
        if ($main_service && $main_service->can("assign_event_destination")) {
            $assigned = $main_service->assign_event_destination($event, $self->{nodes}, $self->{node});
        }
        else {
            $assigned = $self->assign_event_destination_by_round_robin($event);
        }
    }
    &App::sub_exit($assigned) if ($App::trace);
    return($assigned);
}

sub assign_event_destination_by_round_robin {
    &App::sub_entry if ($App::trace);
    my ($self, $event) = @_;
    
    my $assigned = undef;
    my $nodes = $self->{nodes};
    if ($#$nodes > -1) {
        my $node_idx = $self->{node}{ALL}{last_node_idx};
        $node_idx = (defined $node_idx) ? $node_idx + 1 : 0;
        $node_idx = 0 if ($node_idx > $#$nodes);
        $event->{destination} = $nodes->[$node_idx];
        $self->{node}{ALL}{last_node_idx} = $node_idx;
        $assigned = 1;
    }

    &App::sub_exit($assigned) if ($App::trace);
    return($assigned);
}

sub poe_receive_node_status {
    &App::sub_entry if ($App::trace);
    my ($self, $kernel, $args) = @_[OBJECT, KERNEL, ARG0];
    my ($node, $sys_info) = @$args;

    $self->profile_start("poe_receive_node_status") if $self->{poe_profile};
    $self->log({level=>3},"poe_receive_node_status: BEGIN $node - " .
               "load=$sys_info->{system_load}, " .
               "memfree=$sys_info->{memfree}/$sys_info->{memtotal} " .
               "swapfree=$sys_info->{swapfree}/$sys_info->{swaptotal}\n") if $self->{options}{poe_trace};
    $self->set_node_up($node, $sys_info);
    $self->log({level=>3},"poe_receive_node_status: END   $node\n") if $self->{options}{poe_trace};
    $self->profile_stop("poe_receive_node_status") if $self->{poe_profile};

    &App::sub_exit() if ($App::trace);
}

sub poe_run_event {
    &App::sub_entry if ($App::trace);
    my ( $self, $kernel, $heap, $event ) = @_[ OBJECT, KERNEL, HEAP, ARG0 ];

    my ($event_str);
    my $args = $event->{args} || [];
    my $args_str = join(",", @$args);
    if ($event->{name}) {
        my $service_type = $event->{service_type} || "SessionObject";
        $event_str = "$service_type($event->{name}).$event->{method}";
    }
    else {
        $event_str = "$event->{method}";
    }
    $self->profile_start("poe_run_event: $event_str") if $self->{poe_profile};
    $self->log({level=>3},"poe_run_event: BEGIN $event_str\n") if $self->{poe_trace};
    $self->send_event($event);
    $self->log({level=>3},"poe_run_event: END   $event_str\n") if $self->{poe_trace};
    $self->profile_stop("poe_run_event: $event_str") if $self->{poe_profile};
    &App::sub_exit() if ($App::trace);
}

sub state {
    &App::sub_entry if ($App::trace);
    my ($self) = @_;

    my $datetime = time2str("%Y-%m-%d %H:%M:%S", time());
    my $state = "Cluster Controller: $self->{host}:$self->{port}  procs[$self->{num_procs}/$self->{max_procs}:max]  async_events[$self->{num_async_events}/$self->{max_async_events}:max/$self->{max_async_events_per_node}:per]\n[$datetime]\n";
    $state .= "\n";
    $state .= $self->_state();

    &App::sub_exit($state) if ($App::trace);
    return($state);
}

sub _state {
    &App::sub_entry if ($App::trace);
    my ($self) = @_;

    my $state = "";

    my (@nodes);
    @nodes = @{$self->{nodes}} if ($self->{nodes});
    $state .= "Nodes: up [@nodes] last dispatched [$self->{node}{ALL}{last_node_idx}]\n";
    my ($memfree, $memtotal, $swapfree, $swaptotal);
    foreach my $node (sort keys %{$self->{node}}) {
        next if ($node eq "ALL");
        $state .= sprintf("   %-16s %4s : %3d/%3d max : [Load:%4.1f][System Load:%4.1f][Mem:%5.1f%%/%7d][Swap:%5.1f%%/%7d] : [Up:%19s][Last:%19s]\n", $node,
            $self->{node}{$node}{up} ? "UP" : "down",
            $self->{node}{$node}{num_async_events} || 0,
            $self->{node}{$node}{max_async_events} || 0,
            $self->{node}{$node}{load} || 0,
            $self->{node}{$node}{system_load} || 0,
            $self->{node}{$node}{memtotal} ? 100*($self->{node}{$node}{memtotal} - $self->{node}{$node}{memfree})/$self->{node}{$node}{memtotal} : 0,
            $self->{node}{$node}{memtotal} || 0,
            $self->{node}{$node}{swaptotal} ? 100*($self->{node}{$node}{swaptotal} - $self->{node}{$node}{swapfree})/$self->{node}{$node}{swaptotal} : 0,
            $self->{node}{$node}{swaptotal} || 0,
            $self->{node}{$node}{up_datetime},
            $self->{node}{$node}{datetime});
    }

    $state .= $self->SUPER::_state();

    &App::sub_exit($state) if ($App::trace);
    return($state);
}

sub set_node_up {
    &App::sub_entry if ($App::trace);
    my ($self, $node, $sys_info) = @_;
    my ($retval);
    if (!$self->{node}{$node}{up}) {
        $self->{node}{$node}{up_datetime} = time2str("%Y-%m-%d %H:%M:%S", time());
        if ($self->{node}{$node}{up}) {
            $retval = "ok";
        }
        else {
            $self->{node}{$node}{up} = 1;
            $self->set_nodes();
            $retval = "new";
        }
    }
    if ($sys_info) {
        $self->{node}{$node}{datetime} = time2str("%Y-%m-%d %H:%M:%S", time());
        foreach my $sys_var (keys %$sys_info) {
            $self->{node}{$node}{$sys_var} = $sys_info->{$sys_var};
        }
    }
    &App::sub_exit($retval) if ($App::trace);
    return($retval);
}

sub set_node_down {
    &App::sub_entry if ($App::trace);
    my ($self, $node) = @_;
    my $runtime_event_token_prefix = $node;
    $runtime_event_token_prefix =~ s/:/-/;
    $self->reset_running_async_events($runtime_event_token_prefix);
    $self->{node}{$node}{up} = 0;
    $self->set_nodes();
    &App::sub_exit() if ($App::trace);
}

sub set_nodes {
    &App::sub_entry if ($App::trace);
    my ($self) = @_;
    my (@nodes);
    foreach my $node (sort keys %{$self->{node}}) {
        if ($self->{node}{$node}{up}) {
            push(@nodes, $node);
        }
    }
    $self->{nodes} = \@nodes;
    $self->{max_async_events} = $self->{max_async_events_per_node} * ($#nodes + 1);
    my $main_service = $self->{main_service};
    if ($main_service && $main_service->can("capacity_change")) {
        $main_service->capacity_change($self->{max_async_events}, \@nodes, $self->{node});
    }
    &App::sub_exit() if ($App::trace);
}

sub shutdown {
    &App::sub_entry if ($App::trace);
    my $self = shift;
    $self->shutdown_nodes();
    $self->write_node_file();
    $self->SUPER::shutdown();
    &App::sub_exit() if ($App::trace);
}

sub shutdown_nodes {
    &App::sub_entry if ($App::trace);
    my $self = shift;
    foreach my $node (@{$self->{nodes}}) {
        if ($node =~ /^([^:]+):([0-9]+)$/) {
            my $remote_server_name = "poe_${1}_${2}";
            my $remote_session_alias = $self->{poe_session_name};  # remote is same as local
            my $remote_session_state = "poe_shutdown_node";
            my $kernel = $self->{poe_kernel};
            $kernel->post("IKC", "post", "poe://$remote_server_name/$remote_session_alias/$remote_session_state");
        }
        else {
            $self->log({level=>2},"ERROR unparseable node [$node]\n");
        }
    }
    &App::sub_exit() if ($App::trace);
}

sub startup_nodes {
    &App::sub_entry if ($App::trace);
    my ($self, $options) = @_;

    my $startup = $options->{startup};

    my ($node, $msg, $host, $port, $cmd);
    if ($startup eq "1") {
        $self->read_node_file();
    }
    else {
        foreach $node (split(/,/,$startup)) {
            $self->{node}{$node} = {};
        }
    }

    my $cmd_fmt = $self->{options}{"app.context.node_start_cmd"} || "ssh -f {host} mvnode --port={port}";
    foreach $node (keys %{$self->{node}}) {
        if ($node =~ /^([^:]+):([0-9]+)$/) {
            $host = $1;
            $port = $2;
            $cmd = $cmd_fmt;
            $cmd =~ s/{host}/$host/g;
            $cmd =~ s/{port}/$port/g;
            $self->log({level=>3},"Starting Node [$node]: [$cmd]\n") if $self->{options}{poe_trace};
            system("$cmd < /dev/null &");
        }
        else {
            $self->log({level=>2},"ERROR unparseable node [$node]\n");
        }
    }
    &App::sub_exit() if ($App::trace);
}

sub write_node_file {
    &App::sub_entry if ($App::trace);
    my $self = shift;
    my $prefix = $self->{options}{prefix};
    my $node_file = "$prefix/log/$self->{options}{app}-$self->{host}:$self->{port}.nodes";
    if (open(FILE, "> $node_file")) {
        foreach my $node (@{$self->{nodes}}) {
            print App::Context::POE::ClusterController::FILE "$node\n";
        }
        close(App::Context::POE::ClusterController::FILE);
    }
    else {
        $self->log({level=>2},"ERROR Can't write node file [$node_file]: $!\n");
    }
    &App::sub_exit() if ($App::trace);
}

sub read_node_file {
    &App::sub_entry if ($App::trace);
    my $self = shift;
    my $prefix = $self->{options}{prefix};
    my $node_file = "$prefix/log/$self->{options}{app}-$self->{host}:$self->{port}.nodes";
    my ($node);
    if (open(FILE, "< $node_file")) {
        while (<App::Context::POE::ClusterController::FILE>) {
            chomp;
            if (/^[^:]+:[0-9]+$/) {
                $node = $_;
                # just take note of its existence. we don't know yet if it is up.
                $self->{node}{$node} = {} if (!defined $self->{node}{$node});
            }
        }
        close(App::Context::POE::ClusterController::FILE);
    }
    &App::sub_exit() if ($App::trace);
}

1;
