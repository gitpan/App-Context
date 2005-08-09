
#############################################################################
## $Id: HTTP.pm,v 1.9 2005/08/09 19:07:41 spadkins Exp $
#############################################################################

package App::Context::HTTP;

use App;
use App::Context;
@ISA = ( "App::Context" );
use App::UserAgent;

use strict;

=head1 NAME

App::Context::HTTP - context in which we are currently running

=head1 SYNOPSIS

   # ... official way to get a Context object ...
   use App;
   $context = App->context();
   $config = $context->config();   # get the configuration
   $config->dispatch_events();     # dispatch events

   # ... alternative way (used internally) ...
   use App::Context::HTTP;
   $context = App::Context::HTTP->new();

=cut

#############################################################################
# DESCRIPTION
#############################################################################

=head1 DESCRIPTION

A Context class models the environment (aka "context)
in which the current process is running.
For the App::Context::HTTP class, this models any of the
web application runtime environments which employ the HTTP protocol
and produce HTML pages as output.  This includes CGI, mod_perl, FastCGI,
etc.  The difference between these environments is not in the Context
but in the implementation of the Request and Response objects.

=cut

#############################################################################
# PROTECTED METHODS
#############################################################################

=head1 Protected Methods:

The following methods are intended to be called by subclasses of the
current class.

=cut

#############################################################################
# _init()
#############################################################################

=head2 _init()

The _init() method is called from within the standard Context constructor.

The _init() method sets debug flags.

    * Signature: $context->_init($args)
    * Param:     $args            hash{string} [in]
    * Return:    void
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    $context->_init($args);

=cut

sub _init {
    &App::sub_entry if ($App::trace);
    my ($self, $args) = @_;
    $args = {} if (!defined $args);
    eval {
        $self->{user_agent} = App::UserAgent->new($self);
    };
    $self->add_message("Context::HTTP::_init(): $@") if ($@);
    &App::sub_exit() if ($App::trace);
}

sub _default_session_class {
    &App::sub_entry if ($App::trace);
    my $session_class = "App::Session::HTMLHidden";
    &App::sub_exit($session_class) if ($App::trace);
    return($session_class);
}

#############################################################################
# PROTECTED METHODS
#############################################################################

=head1 Protected Methods

These methods are considered protected because no class is ever supposed
to call them.  They may however be called by the context-specific drivers.

=cut

sub dispatch_events_begin {
    &App::sub_entry if ($App::trace);
    my ($self) = @_;
    my $events = $self->{events};
    my $request = $self->request();

    my $session_id = $request->get_session_id();
    my $session = $self->session($session_id);
    $self->set_current_session($session);

    my $request_events = $request->get_events();
    if ($request_events && $#$request_events > -1) {
        push(@$events, @$request_events);
    }
    &App::sub_exit() if ($App::trace);
}

sub dispatch_events {
    &App::sub_entry if ($App::trace);
    my ($self) = @_;

    $self->dispatch_events_begin();

    my $events = $self->{events};
    my ($event, $service, $name, $method, $args);
    my $results = "";
    # my $display_current_widget = 1;

    eval {
        while ($#$events > -1) {
            $event = shift(@$events);
            ($service, $name, $method, $args) = @$event;
            #if ($service eq "SessionObject") {
            #    $self->call($service, $name, $method, $args);
            #}
            #else {
                $results = $self->call($service, $name, $method, $args);
                #$results = [ $results ] if (!ref($results));
            #    $display_current_widget = 0;
            #}
        }
        #if ($display_current_widget) { }
        #if (! defined $results) {
            my $type = $self->so_get("default","ctype","SessionObject");
            my $name = $self->so_get("default","cname");
            #if ($xyz) {
                $results = $self->service($type, $name);
            #}
        #}

        my $response = $self->response();
        my $ref = ref($results);
        if (!$ref || $ref eq "ARRAY" || $ref eq "HASH") {
            $response->content($results);
        }
        elsif ($results->isa("App::Service")) {
            $response->content($results->content());
            $response->content_type($results->content_type());
        }
        else {
            $response->content($results->internals());
        }

        $self->send_response();
    };
    if ($@) {
        $self->send_error($@);
    }

    if ($self->{options}{debug_context}) {
        print STDERR $self->dump();
    }

    $self->dispatch_events_finish();
    &App::sub_exit() if ($App::trace);
}

sub dispatch_events_finish {
    &App::sub_entry if ($App::trace);
    my ($self) = @_;
    $self->restore_default_session();
    $self->shutdown();  # assume we won't be doing anything else (this can be overridden)
    &App::sub_exit() if ($App::trace);
}

# this code needs to be restored at the Context->dispatch_events() level
#       $name = $context->so_get("default", "name");
#       $service = $context->so_get("default", "service");
#       $returntype = $context->so_get("default", "returntype");
#       # print "name=[$curr_name] service=[$curr_service] returntype=[$curr_returntype]\n";
# ...
#       $context->so_set("default", "curr_service", $curr_service);
#       $context->so_set("default", "curr_name",    $curr_name);
#       # $context->so_set("default", "curr_method",  $curr_method);
#       # $context->so_set("default", "curr_args",    $curr_args);
#       $context->so_set("default", "curr_returntype",    $curr_returntype);
# ...
#       if ($service) {
#           my $service = $context->service($service, $name);
#           my $response = $context->response();
#           if (!$service) {
#               $response->content("Service not defined: $service($name)\n");
#           }
#           elsif (!$service->can($method)) {
#               $response->content("Method not defined on Service: $service($name).$method($args)\n");
#           }
#           else {
#               my @results = $service->$method($args);
#               if ($#results == -1) {
#                   $response->content($service->internals());
#               }
#               elsif ($#results == 0) {
#                   $response->content($results[0]);
#                   $response->content_type($service->content_type());
#               }
#               else {
#                   $response->content(\@results);
#               }
#           }
#       }

sub send_error {
    &App::sub_entry if ($App::trace);
    my ($self, $errmsg) = @_;
    print <<EOF;
Content-type: text/plain

-----------------------------------------------------------------------------
AN ERROR OCCURRED in App::Context::HTTP->dispatch_events()
-----------------------------------------------------------------------------
$errmsg

-----------------------------------------------------------------------------
Additional messages from earlier stages may be relevant if they exist below.
-----------------------------------------------------------------------------
$self->{messages}
EOF
    &App::sub_exit() if ($App::trace);
}

#############################################################################
# request()
#############################################################################

=head2 request()

    * Signature: $context->request()
    * Param:     void
    * Return:    void
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    $context->request();

The request() method gets the current Request being handled in the Context.

=cut

sub request {
    &App::sub_entry if ($App::trace);
    my $self = shift;

    if (! defined $self->{request}) {

        #################################################################
        # REQUEST
        #################################################################

        my $request_class = $self->get_option("request_class");
        if (!$request_class) {
            my $gateway = $ENV{GATEWAY_INTERFACE};
            # TODO: need to distinguish between PerlRun, Registry, libapreq, other
            if (defined $gateway && $gateway =~ /CGI-Perl/) {  # mod_perl?
                $request_class = "App::Request::CGI";
            }
            elsif ($ENV{HTTP_USER_AGENT}) {  # running as CGI script?
                $request_class = "App::Request::CGI";
            }
            else {
                $request_class = "App::Request::CGI";
            }
        }

        eval {
            $self->{request} = App->new($request_class, "new", $self, $self->{options});
        };
        if ($@) {
            $self->add_message("Context::HTTP::request(): $@");
            print STDERR "request=$self->{request} err=[$@]\n";
        }
    }

    &App::sub_exit($self->{request}) if ($App::trace);
    return $self->{request};
}

#############################################################################
# response()
#############################################################################

=head2 response()

    * Signature: $context->response()
    * Param:     void
    * Return:    void
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    $context->response();

The response() method gets the current Request being handled in the Context.

=cut

sub response {
    &App::sub_entry if ($App::trace);
    my $self = shift;

    my $response = $self->{response};
    if (!defined $response) {

        #################################################################
        # RESPONSE
        #################################################################

        my $response_class = $self->get_option("response_class", "App::Response");

        eval {
            $response = App->new($response_class, "new", $self, $self->{options});
        };
        $self->{response} = $response;
        $self->add_message("Context::HTTP::response(): $@") if ($@);
    }

    &App::sub_exit($response) if ($App::trace);
    return($response);
}

#############################################################################
# send_response()
#############################################################################

=head2 send_response()

    * Signature: $context->send_response()
    * Param:     void
    * Return:    void
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    $context->send_response();

=cut

#sub send_results {
#    my ($self, $results) = @_;
#
#    my ($serializer, $returntype);
#
#    if (ref($results)) {
#        $returntype = $self->{returntype};
#        $serializer = $self->serializer($returntype);
#        $results = $serializer->serialize($results);
#    }
#
#    if ($self->{messages}) {
#        my $msg = $self->{messages};
#        $self->{messages} = "";
#        $msg =~ s/<br>/\n/g;
#        print $msg;
#    }
#    else {
#        print $results;
#    }
#}
#
#sub send_error {
#    my ($self, $errmsg) = @_;
#    print <<EOF;
#-----------------------------------------------------------------------------
#AN ERROR OCCURRED in App::Context->dispatch_events()
#-----------------------------------------------------------------------------
#$errmsg
#
#-----------------------------------------------------------------------------
#Additional messages from earlier stages may be relevant if they exist below.
#-----------------------------------------------------------------------------
#$self->{messages}
#EOF
#}

sub send_response {
    &App::sub_entry if ($App::trace);
    my $self = shift;

    my ($serializer, $response, $ctype, $content, $content_type, $headers);
    $response     = $self->response();
    $content      = $response->content();

    if (ref($content)) {
        $ctype = $self->so_get("default", "ctype", "default");
        $serializer = $self->serializer($ctype);
        $content = $serializer->serialize($content);
        $content_type = $serializer->serialized_content_type();
    }
    $content_type = $response->content_type() if (!$content_type);
    $content_type = "text/plain" if (!$content_type);
    $headers      = "Content-type: $content_type\n";

    if (defined $self->{headers}) {
        $headers .= $self->{headers};
        delete $self->{headers}
    }

    if ($self->{options}{gzip}) {
        my $user_agent = $self->user_agent();
        my $gzip_ok    = $user_agent->supports("http.header.accept-encoding.x-gzip");

        if ($gzip_ok) {
            $headers .= "Content-encoding: gzip\n";
            use Compress::Zlib;
            $content = Compress::Zlib::memGzip($content);
        }
    }

    if ($self->{messages}) {
        my $msg = $self->{messages};
        $self->{messages} = "";
        $msg =~ s/<br>/\n/g;
        print "Content-type: text/plain\n\n", $msg, "\n";
    }
    else {
        print $headers, "\n", $content;
    }
    &App::sub_exit() if ($App::trace);
}

#############################################################################
# set_header()
#############################################################################

=head2 set_header()

    * Signature: $context->set_header()
    * Param:     void
    * Return:    void
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    $context->set_header();

=cut

sub set_header {
    &App::sub_entry if ($App::trace);
    my ($self, $header) = @_;
    if ($self->{headers}) {
        $self->{headers} .= $header;
    }
    else {
        $self->{headers} = $header;
    }
    &App::sub_exit() if ($App::trace);
}

#############################################################################
# user_agent()
#############################################################################

=head2 user_agent()

The user_agent() method returns a UserAgent objects which is primarily
useful to see what capabilities the user agent (browser) supports.

    * Signature: $user_agent = $context->user_agent();
    * Param:  void
    * Return: $user_agent    App::UserAgent
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    $user_agent = $context->user_agent();

=cut

sub user_agent {
    &App::sub_entry if ($App::trace);
    my $self = shift;
    my $user_agent = $self->{user_agent};
    &App::sub_exit($user_agent) if ($App::trace);
    return($user_agent);
}

#############################################################################
# PUBLIC METHODS
#############################################################################

=head1 Public Methods:

=cut

#############################################################################
# user()
#############################################################################

=head2 user()

The user() method returns the username of the authenticated user.
The special name, "guest", refers to the unauthenticated (anonymous) user.

    * Signature: $username = $self->user();
    * Param:  void
    * Return: string
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    $username = $context->user();

In a request/response environment, this turns out to be a convenience
method which gets the authenticated user from the current Request object.

=cut

sub user {
    &App::sub_entry if ($App::trace);
    my $self = shift;
    my $user = $self->request()->user();
    my $switchable_users = $self->get_option("switchable_users");
    if ($switchable_users && $switchable_users =~ /\b$user\b/) {
        # check more carefully ...
        if ($switchable_users eq $user ||
            $switchable_users =~ /:$user:/ ||
            $switchable_users =~ /^$user:/ ||
            $switchable_users =~ /:$user$/) {
            my $newuser = $self->so_get("default","u");
            if ($newuser) {
                $user = $newuser;
            }
        }
    }
    &App::sub_exit($user) if ($App::trace);
    return $user;
}

1;

