
#############################################################################
## $Id: HTTP.pm,v 1.1 2002/09/18 02:54:11 spadkins Exp $
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
# init()
#############################################################################

=head2 init()

The init() method is called from within the standard Context constructor.

The init() method sets debug flags.

    * Signature: $context->init($args)
    * Param:     $args            hash{string} [in]
    * Return:    void
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    $context->init($args);

=cut

sub init {
    my ($self, $args) = @_;
    $args = {} if (!defined $args);
    eval {
        $self->{user_agent} = App::UserAgent->new($self);
    };
    $self->add_message("Context::HTTP::init(): $@") if ($@);
}

#############################################################################
# PROTECTED METHODS
#############################################################################

=head1 Protected Methods

These methods are considered protected because no class is ever supposed
to call them.  They may however be called by the context-specific drivers.

=cut

#############################################################################
# dispatch_events()
#############################################################################

=head2 dispatch_events()

The dispatch_events() method is called by the CGI script
in order to get the Context object rolling.  It causes the program to
process the CGI request, interpret and dispatch encoded events in the 
request and exit.

In concept, the dispatch_events() method would not return until all
events for a Session were dispatched.  However, the reality of the CGI
context is that events associated with a Session occur in many different
processes over different CGI requests.  Therefore, the CGI Context
implements the dispatch_events() method to return after processing
all of the events of a single request, assuming that it will be called
again when the next CGI request is received.

    * Signature: $context->dispatch_events()
    * Param:     void
    * Return:    void
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    $context->dispatch_events();

=cut

sub dispatch_events {
    my ($self) = @_;

    my ($request);

    eval {
        $request = $self->request();
        $request->process();
        $self->send_response();
    };
    if ($@) {
        print <<EOF;
Content-type: text/plain

-----------------------------------------------------------------------------
AN ERROR OCCURRED in App::Context::HTTP->dispatch_events()
-----------------------------------------------------------------------------
$@

-----------------------------------------------------------------------------
Additional messages from earlier stages may be relevant if they exist below.
-----------------------------------------------------------------------------
$self->{messages}
EOF
    }

    $self->shutdown();
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

sub send_response {
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

    if ($self->{initconf}{gzip}) {
        my $user_agent = $self->user_agent();
        my $gzip_ok    = $user_agent->supports("http.header.accept-encoding.x-gzip");

        if ($gzip_ok) {
            $headers .= "Content-encoding: gzip\n";
            use Compress::Zlib;
            $content = Compress::Zlib::memGzip($content);
        }
    }

    print $headers, "\n", $content;
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
    my $self = shift;

    return $self->{request} if (defined $self->{request});

    #################################################################
    # REQUEST
    #################################################################

    my $request_class = $self->iget("requestClass");
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
        $self->{request} = App->new($request_class, "new", $self, $self->{initconf});
    };
    $self->add_message("Context::HTTP::request(): $@") if ($@);

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
    my $self = shift;

    return $self->{response} if (defined $self->{response});

    #################################################################
    # RESPONSE
    #################################################################

    #my $response_class = $self->iget("responseClass", "App::Response::HTML");
    my $response_class = $self->iget("responseClass", "App::Response");

    eval {
        $self->{response} = App->new($response_class, "new", $self, $self->{initconf});
    };
    $self->add_message("Context::HTTP::response(): $@") if ($@);

    return $self->{response};
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
    my $self = shift;
    $self->{user_agent};
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
    my $self = shift;
    return $self->request()->user();
}

1;

