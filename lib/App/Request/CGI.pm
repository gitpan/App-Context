
#############################################################################
## $Id: CGI.pm,v 1.12 2004/09/02 20:56:51 spadkins Exp $
#############################################################################

package App::Request::CGI;

use App;
use App::Request;
@ISA = ( "App::Request" );
use CGI;

use strict;

=head1 NAME

App::Request::CGI - the request

=head1 SYNOPSIS

   # ... official way to get a Request object ...
   use App;
   $context = App->context();
   $request = $context->request();  # get the request

   # ... alternative way (used internally) ...
   use App::Request::CGI;
   $request = App::Request::CGI->new();

=cut

#############################################################################
# CONSTANTS
#############################################################################

=head1 DESCRIPTION

A Request class implemented using the CGI class.

=cut

#############################################################################
# PROTECTED METHODS
#############################################################################

=head1 Protected Methods:

The following methods are intended to be called by subclasses of the
current class (or environmental, "main" code).

=cut

#############################################################################
# _init()
#############################################################################

=head2 _init()

The _init() method is called from within the standard Request constructor.
The _init() method in this class does nothing.
It allows subclasses of the Request to customize the behavior of the
constructor by overriding the _init() method. 

    * Signature: $request->_init()
    * Param:     void
    * Return:    void
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    $request->_init();

=cut

sub _init {
    &App::sub_entry if ($App::trace);
    my ($self, $options) = @_;
    my ($cgi, $var, $value, $app, $file);
    $options = {} if (!defined $options);

    $app = $options->{app};
    if (!defined $app) {
        # untaint the $app
        $0 =~ /(.*)/;
        $app = $1;
    }

    my $debug_request = $options->{debug_request} || "";
    my $replay = ($debug_request eq "replay" || $options->{replay});
    my $record = ($debug_request eq "record" && !$replay);

    #################################################################
    # read environment variables
    #################################################################

    if ($replay) {
        $file = "$app.env";
        if (open(App::FILE, "< $file")) {
            foreach $var (keys %ENV) {
                delete $ENV{$var};     # unset all environment variables
            }
            while (<App::FILE>) {
                chop;
                /^([^=]+)=(.*)/;       # parse variable, value (and untaint)
                $var = $1;             # get variable name
                $value = $2;           # get variable value
                $ENV{$var} = $value;   # restore environment variable
            }
            close(App::FILE);
        }
    }

    if ($record) {
       $file = "$app.env";
       if (open(App::FILE, "> $file")) {
          foreach $var (keys %ENV) {
             print App::FILE "$var=$ENV{$var}\n"; # save environment variables
          }
          close(App::FILE);
       }
    }

    #################################################################
    # READ HTTP PARAMETERS (CGI VARIABLES)
    #################################################################

    if ($replay) {
        # when the "debug_request" is in "replay", the saved CGI environment from
        # a previous query (when "debug_request" was "record") is used
        $file = "$app.vars";
        open(App::FILE, "< $file") || die "Unable to open $file: $!";
        $cgi = new CGI(*App::FILE); # Get vars from debug file
        close(App::FILE);
    }
    else {  # ... the normal path
        if (defined $options && defined $options->{cgi}) {
            # this allows for migration from old scripts where they already
            # read in the CGI object and they pass it in to App-Context as an arg
            $cgi = $options->{cgi};
        }
        else {
            # this is the normal path for App-Context execution, where the Request::CGI
            # is responsible for reading its environment
            $cgi = CGI->new();
            $options->{cgi} = $cgi if (defined $options);
        }
    }

    # when the "debug_request" is "record", save the CGI vars
    if ($record) {
        $file = "$app.vars";
        if (open(App::FILE, "> $file")) {
            $cgi->save(*App::FILE);     # Save vars to debug file
            close(App::FILE);
        }
    }

    #################################################################
    # LANGUAGE
    #################################################################

    my $lang = "en_us";  # default
    if (defined $ENV{HTTP_ACCEPT_LANGUAGE}) {
        $lang = lc($ENV{HTTP_ACCEPT_LANGUAGE});
        $lang =~ s/ *,.*//;
        $lang =~ s/-/_/g;
    }
    elsif ($options->{lang}) {
        $lang = lc($options->{lang});
        $lang =~ s/ *,.*//;
        $lang =~ s/-/_/g;
    }
    $self->{lang} = $lang;    # TODO: do something with the $lang ...

    $self->{cgi} = $cgi;
    &App::sub_exit() if ($App::trace);
}

#############################################################################
# PUBLIC METHODS
#############################################################################

=head1 Public Methods

=cut

#############################################################################
# get_session_id()
#############################################################################

=head2 get_session_id()

The get_session_id() method returns the session_id in the request.

    * Signature: $session_id = $request->get_session_id();
    * Param:  void
    * Return: $session_id     string
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    $session_id = $request->get_session_id();

=cut

sub get_session_id {
    &App::sub_entry if ($App::trace);
    my $self = shift;
    my $session_id = $self->{cgi}->param("session_id");
    &App::sub_exit($session_id) if ($App::trace);
    return($session_id);
}

#############################################################################
# get_events()
#############################################################################

=head2 get_events()

The get_events() method analyzes an HTTP request and returns the events
within it which should be executed.

It is called primarily from the event loop handler, dispatch_events().
However, it might also be called from external software if that code manages
the event loop itself.  i.e. it instantiates the CGI object outside of
the Context and passes it in, never calling dispatch_events().

    * Signature: $request->get_events()
    * Signature: $request->get_events($cgi)
    * Param:     $cgi            (CGI)
    * Return:    void
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    $request->get_events();

=cut

sub get_events {
    &App::sub_entry if ($App::trace);
    my ($self, $cgi) = @_;

    if (!defined $cgi) {
        $cgi = $self->{cgi};
    }
    elsif (!defined $self->{cgi}) {
        $self->{cgi} = $cgi;
    }
    my $context = $self->{context};

    $context->dbgprint("Request::CGI->get_events() cgi=$cgi")
        if ($App::DEBUG && $context->dbg(1));

    my (@events);

    if (defined $cgi) {
        my ($service, $name, $method, $args, $temp);
        my $request_method = $cgi->request_method() || "GET";
        if ($request_method eq "GET") {
            # get PATH_INFO and see if an event is embedded there
            my $path_info = $ENV{PATH_INFO};
            $path_info =~ s!/$!!;   # delete trailing "/"
            my $options = $context->options();
            my $app = $options->{app};
            if ($path_info && $app) {
                # this is because App::Options uses the first leg of the PATH_INFO
                # to set the {app} if the program name is the generic "app"
                $path_info =~ s!/$app!!;  # delete leading $app prefix
            }

            $path_info =~ s!:[a-zA-Z0-9_]+$!!;  # delete trailing :<returntype>
            $path_info =~ s!\.(html|xml|yaml|csv|pdf|perl)$!!;  # delete trailing .<returntype>

            if ($path_info =~ s!^/([A-Z][A-Za-z0-9]*)/!/!) {
                $service = $1;
            }
            else {
                $service = "SessionObject";
            }

            if ($path_info =~ s!\.([a-zA-Z0-9_]+)\(([^\(\)]*)\)$!!) {
                $method  = $1;
                $args    = $2;
            }
            else {
                $method  = "";
                $args    = "";
            }

            if ($path_info =~ m!^/([a-zA-Z._-]+)$!) {
                $name = $1;
            }
            else {
                $name = $app;
            }

            # override PATH_INFO with CGI variables
            $temp    = $cgi->param("service");
            $service = $temp if ($temp);
            $temp    = $cgi->param("name");
            $name    = $temp if ($temp);
            $temp    = $cgi->param("method");
            $method  = $temp if ($temp);
            $temp    = $cgi->param("args");
            $args    = $temp if ($temp);

            if (defined $args) {
                if ($args =~ /^\s*$/) {
                    $args = [];
                }
                else {
                    my $ser = $context->serializer("one_line", class => "App::Serializer::OneLine");
                    $args = $ser->deserialize($args);
                }
            }

            if ($service && $name && $method) {
                push(@events, [ $service, $name, $method, $args ]);
            }
            elsif ($service && $name) {
                $context->so_set("default","ctype",$service);
                $context->so_set("default","cname",$name);
            }
        }

        ##########################################################
        # For each CGI variable, do the appropriate thing
        #  1. "app.event.*" variable is an event and gets handled last
        #  2. "app.*"       variable is a "multi-level hash key" under $context
        #  3. "name{m}[1]"  variable is a "multi-level hash key" under $context->{session_object}{$name}
        #  4. "name"        variable is a "multi-level hash key"
        ##########################################################
        my (@eventvars, $var, @values, @tmp, $value, $mlhashkey);
        @eventvars = ();
        foreach $var ($cgi->param()) {
            if ($var =~ /^app\.event/) {
                push(@eventvars, $var);
            }
            elsif ($var =~ /^app\.session/) {
                # do nothing.
                # these vars are used in the Session restore() to restore state.
            }
            else {
                @values = $cgi->param($var);
                if ($#values > 0) {
                    @tmp = ();
                    foreach $value (@values) {
                        if ($value eq "{:delete:}") {
                            my $delvar = $var;
                            $delvar =~ s/\[\]$//;
                            $context->so_delete($name, $delvar);
                        }
                        else {
                            push(@tmp, $value);
                        }
                    }
                    @values = @tmp;
                }

                if ($var =~ s/\[\]$//) {
                    $value = [ @values ];
                }
                elsif ($#values == -1) {
                    $value = "";
                }
                elsif ($#values == 0) {
                    $value = $values[0];
                }
                else {
                    $value = join(",",@values);
                }

                $context->dbgprint("Request::CGI->get_events() var=[$var] value=[$value]")
                    if ($App::DEBUG && $context->dbg(1));

                if ($var =~ /[\[\]\{\}\.]/) {
                    $context->so_set($var, "", $value);
                }
                elsif ($var eq "service" || $var eq "name" || $var eq "method" ||
                       $var eq "args" || $var eq "returntype") { 
                    # this has already been done
                    # $context->so_set("default", $var, $value);
                }
                # Autoattribute vars: e.g. "width" (an attribute of session_object named in request)
                elsif ($name) {
                    $context->so_set($name, $var, $value);
                }
                # Simple vars: e.g. "width" (gets dumped in the "default" session_object)
                else {
                    $context->so_set("default", $var, $value);
                }
            }
        }

        my ($key, $fullkey, $arg, @args, $event, %x, %y, $x, $y);
        foreach $key (@eventvars) {

            # These events come from <input type=submit> type controls
            # The format is name="app.event.{session_objectName}.{event}(args)"
            # Note: this format is important because the "value" is needed for display purposes

            $context->dbgprint("Request::CGI->get_events() eventvar=[$key]")
                if ($App::DEBUG && $context->dbg(1));

            if ($key =~ /^app\.event\./) {

                $args = "";
                @args = ();
                if ($key =~ /\((.*)\)/) {             # look for anything inside parentheses
                    $args = $1;
                }
                if ($args eq "") {
                    # do nothing, @args = ()
                }
                elsif ($args =~ /\{/) {  # } balance
                    foreach $arg (split(/ *, */,$args)) {
                        if ($arg =~ /^\{(.*)\}$/) {
                            push(@args, $context->so_get($1));
                        }
                        else {
                            push(@args, $arg);
                        }
                    }
                }
                else {
                    @args = split(/ *, */,$args) if ($args ne "");
                }

                # <input type=image name=joe> returns e.g. joe.x=20 joe.y=35
                # these two variables get turned into one event with $x, $y added to the end of the @args
                $fullkey = $key;
                if ($key =~ /^(.*)\.x$/) {
                    $key = $1;
                    $x{$key} = $cgi->param($fullkey);
                    next if (!defined $y{$key});
                    push(@args, $x{$key});            # tack $x, $y coordinates on at the end
                    push(@args, $y{$key});
                }
                elsif ($key =~ /^(.*)\.y$/) {
                    $key = $1;
                    $y{$key} = $cgi->param($fullkey);
                    next if (!defined $x{$key});
                    push(@args, $x{$key});            # tack $x, $y coordinates on at the end
                    push(@args, $y{$key});
                }
                else {
                    push(@args, $cgi->param($key));   # tack the label on at the end
                }

                $key =~ s/^app\.event\.//;   # get rid of prefix
                $key =~ s/\(.*//;            # get rid of args

                $context->dbgprint("Request::CGI->get_events() key=[$key] args=[@args]")
                    if ($App::DEBUG && $context->dbg(1));

                if ($key =~ /^([^()]+)\.([a-zA-Z0-9_-]+)$/) {
                    $name = $1;
                    $event = $2;

                    push(@events, [ "SessionObject", $name, $event, [ @args ] ]);

                    #if ($context->session_object_exists($name)) {
                    #    $context->dbgprint("Request::CGI->get_events() handle_event($name, $event, @args) [button]")
                    #        if ($App::DEBUG && $context->dbg(1));
                    #    $context->session_object($name)->handle_event($name, $event, @args);
                    #}
                    #else {
                    #    my ($parent_name);
                    #    $parent_name = $name;
                    #    $context->dbgprint("Request::CGI->get_events() $name doesn't exist, trying parents...")
                    #        if ($App::DEBUG && $context->dbg(1));
                    #    while ($parent_name =~ s/\.[^\.]+$//) {
                    #        if ($context->session_object_exists($parent_name)) {
                    #          $context->dbgprint("Request::CGI->get_events() handle_event($name, $event, @args) [button]")
                    #                if ($App::DEBUG && $context->dbg(1));
                    #            $context->session_object($parent_name)->handle_event($name, $event, @args);
                    #            last;
                    #        }
                    #        $context->dbgprint("Request::CGI->get_events() $parent_name doesn't exist")
                    #            if ($App::DEBUG && $context->dbg(1));
                    #    }
                    #}
                }
            }
            elsif ($key eq "app.event") {

                # These events come from <input type=hidden> type controls
                # They are basically call-backs so that the session_object could clean up something before being viewed
                # The format is name="app.event" value="{session_objectName}.{event}"
                foreach $value ($cgi->param($key)) {

                    if ($value =~ /^([^()]+)\.([a-zA-Z0-9_-]+)/) {

                        $name = $1;
                        $event = $2;
                        $args = "";
                        @args = ();
                        if ($value =~ /\((.*)\)/) {   # look for anything inside parentheses
                            $args = $1;
                        }
                        @args = split(/ *, */,$args) if ($args ne "");
                        push(@events, [ "SessionObject", $name, $event, [ @args ] ]);

                        #$context->dbgprint("Request::CGI->get_events() handle_event($name, $event, @args) [hidden/other]")
                        #    if ($App::DEBUG && $context->dbg(1));

                        #$context->session_object($name)->handle_event($name, $event, @args);
                    }
                }
            }
        }

        $context->dbgprint("Request->get_events(): $service($name).$method($args)")
            if ($App::DEBUG && $context->dbg(1));
    }

    &App::sub_exit(\@events) if ($App::trace);
    return(\@events);
}

sub get_returntype {
    &App::sub_entry if ($App::trace);
    my ($self, $cgi) = @_;

    if (!defined $cgi) {
        $cgi = $self->{cgi};
    }
    elsif (!defined $self->{cgi}) {
        $self->{cgi} = $cgi;
    }
    my ($returntype);
    if ($cgi) {
        $returntype = $cgi->param("returntype");
    }
    if (!$returntype) {
        my $context = $self->{context};
        my $path_info = $ENV{PATH_INFO};
        if ($path_info =~ /:([a-zA-Z0-9_]+)$/) {
            $returntype = $1;
        }
    }
    &App::sub_exit($returntype) if ($App::trace);
    return($returntype);
}

#############################################################################
# user()
#############################################################################

=head2 user()

The user() method returns the username of the authenticated user.
The special name, "guest", refers to the unauthenticated (anonymous) user.

    * Signature: $username = $request->user();
    * Param:  void
    * Return: string
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    $username = $request->user();

=cut

sub user {
    &App::sub_entry if ($App::trace);
    my $self = shift;
    my $user = $ENV{REMOTE_USER} || "guest";
    &App::sub_exit($user) if ($App::trace);
    return ($user);
}

#############################################################################
# header()
#############################################################################

=head2 header()

The header() method returns the specified HTTP header from the request.

    * Signature: $header_value = $request->header($header_name);
    * Param:  $header_name    string
    * Return: $header_value   string
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    $header_value = $request->header("Accept-Encoding");

=cut

sub header {
    &App::sub_entry if ($App::trace);
    my ($self, $header_name) = @_;
    my $header = $self->{cgi}->http($header_name);
    &App::sub_exit($header) if ($App::trace);
    return($header);
}

1;

