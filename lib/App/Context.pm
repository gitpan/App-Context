
#############################################################################
## $Id: Context.pm,v 1.3 2002/10/07 21:55:58 spadkins Exp $
#############################################################################

package App::Context;

use strict;

use App;

use Date::Format;

=head1 NAME

App::Context - context in which we are currently running

=head1 SYNOPSIS

   # ... official way to get a Context object ...
   use App;
   $context = App->context();
   $context->dispatch_events();     # dispatch events
   $conf = $context->conf();        # get the configuration

   # any of the following named parameters may be specified
   $context = App->context(
       contextClass => "App::Context::CGI",
       confClass => "App::Conf::File",   # or any Conf args
   );

   # ... alternative way (used internally) ...
   use App::Context;
   $context = App::Context->new();

=cut

#############################################################################
# CONSTANTS
#############################################################################

=head1 DESCRIPTION

A Context class models the environment (aka "context")
in which the current process is running.

The role of the Context class is to abstract the details of the
various runtime environments (or Platforms) (including their event loops)
so that the basic programming model for the developer is uniform.

Since the Context objects are the objects that initiate events in the
App-Context universe, they must be sure to wrap those event handlers with
try/catch blocks (i.e. "eval{};if($@){}" blocks).

The main functions of the Context class are to

    * load the Conf data,
    * dispatch events from the Context event loop, and
    * manage Session data.

The Context object is always a singleton per process (except in rare cases
like debugging during development). 

Conceptually, the Context may be associated with many
Conf's (one per authenticated user) and
Sessions (one per unique session_id)
in a single process (ModPerl).
However, in practice, it is often
associated with only one Conf or Session throughout the lifetime of
the process (CGI, Cmd).

=cut

#############################################################################
# CLASS GROUP
#############################################################################

=head1 Class Group: Context

The following classes might be a part of the Context Class Group.

=over

=item * Class: App::Context

=item * Class: App::Context::CGI

=item * Class: App::Context::FCGI

=item * Class: App::Context::ModPerl

=item * Class: App::Context::ModPerlRegistry

=item * Class: App::Context::PPerl

=item * Class: App::Context::Cmd

=item * Class: App::Context::Daemon

=item * Class: App::Context::POE

=item * Class: App::Context::SOAP (when acting as a SOAP server)

=item * Class: App::Context::Gtk

=item * Class: App::Context::WxPerl

=back

=cut

#############################################################################
# ATTRIBUTES/CONSTANTS/CLASS VARIABLES/GLOBAL VARIABLES
#############################################################################

=head1 Attributes, Constants, Global Variables, Class Variables

=head2 Master Data Structure Map

 $context
 $context->{debugscope}{$class}          Debugging all methods in class
 $context->{debugscope}{$class.$method}  Debugging a single method
 $context->{initconf}    Args that Context was created with
 $context->{used}{$class}  Similar to %INC, keeps track of what classes used
 $context->{cgi}           (Context::CGI only) the CGI object
 $context->{Conf}{$user} Info from conf file
 [$context->{conf}]
    $conf->{$type}{$name}              Read-only service conf
 $context->{Session}{$session_id}
 [$context->{session}]
    $session->{store}{$type}{$name}      Runtime state which is stored
    $session->{cache}{$type}{$name}      Instances of services

=cut

#############################################################################
# CONSTRUCTOR METHODS
#############################################################################

=head1 Constructor Methods:

=cut

#############################################################################
# new()
#############################################################################

=head2 new()

The App::Context->new() method is rarely called directly.
That is because a $context should always be instantiated by calling
App->context().  This allows for caching of the $context
as a singleton and the autodetection of what type of Context subclass
should in fact be instantiated.

    * Signature: $context = App->new(%named);
    * Param:  contextClass class  [in]
    * Param:  confClass    class  [in]
    * Param:  confFile     string [in]
    * Return: $context     App::Context
    * Throws: Exception::Class::Context
    * Since:  0.01

    Sample Usage: 

    $context = App::Context->new();
    $context = App::Context->new(
        contextClass => 'App::Context::CGI',
        confClass  => 'App::Conf::File',
        confFile   => 'app.xml',
    );

=cut

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless $self, $class;

    my ($args, %args, $i);
    if ($#_ > -1) {
        if (ref($_[0]) eq "HASH") {
            $args = shift;
            pop if ($#_ % 2 == 0);  # throw away odd arg (probably should throw exception)
            for ($i = 0; $i < $#_; $i++) {
                $args->{$_[$i]} = $_[$i+1];
            }
        }
        else {
            $args = ($#_ > -1) ? { @_ } : {};
        }
    }

    my ($conf_class, $session_class);
    %args = %$args;
    $self->{initconf} = \%args;
    $args{context} = $self;

    $conf_class   = $args{confClass};
    $conf_class   = $ENV{APP_CONFIG_CLASS} if (! $conf_class);
    $conf_class   = "App::Conf::File" if (! $conf_class);

    $session_class   = $args{sessionClass};
    $session_class   = "App::Session::HTMLHidden" if (! $session_class);

    if ($App::DEBUG >= 2) {
        my (@str, $key);
        push(@str,"Context->new(): conf=$conf_class session=$session_class\n");
        foreach $key (sort keys %args) {
            push(@str, "   $key => $args{$key}\n");
        }
        $self->dbgprint(join("",@str));
    }

    eval {
        $self->{conf} = App->new($conf_class, "new", \%args);
    };
    $self->add_message($@) if ($@);

    #################################################################
    # DEBUGGING
    #################################################################

    # Supports the following command-line usage:
    #    -debug=1                                      (global debug)
    #    -debug=1,App::Context                     (debug class only)
    #    -debug=3,App::Context,App::Session        (multiple classes)
    #    -debug=6,App::Repository::DBI.select_rows   (indiv. methods)
    my ($debug, $pkg);
    $debug = $args{debug};
    if (defined $debug && $debug ne "") {
        if ($debug =~ s/^([0-9]+),?//) {
            $App::DEBUG = $1;
        }
        if ($debug) {
            foreach $pkg (split(/,/,$debug)) {
                $self->{debugscope}{$pkg} = 1;
            }
        }
    }

    if ($App::DEBUG && $self->dbg(2)) {
        my $file = $self->{initconf}->{confFile};
        $self->dbgprint("Conf [$file]: ");
    }
    if ($App::DEBUG && $self->dbg(4)) {
        $self->dbgprint(join("\n",%{$self->{initconf}}));
    }
    if ($App::DEBUG && $self->dbg(8)) {
        $self->dbgprint($self->{conf}->dump());
    }

    $self->init(\%args);

    eval {
        $self->dbgprint("Context->new(): confClass=$conf_class sessionClass=$session_class (", join(",",%args), ")")
            if ($App::DEBUG && $self->dbg(1));

        $self->{session} = App->new($session_class, "new", \%args);
    };
    $self->add_message($@) if ($@);

    return $self;
}

#############################################################################
# PROTECTED METHODS
#############################################################################

=head1 Protected Methods:

The following methods are intended to be called by subclasses of the
current class (or environmental, "main" code).

=cut

#############################################################################
# init()
#############################################################################

=head2 init()

The init() method is called from within the standard Context constructor.
The init() method in this class does nothing.
It allows subclasses of the Context to customize the behavior of the
constructor by overriding the init() method. 

    * Signature: $context->init($args)
    * Param:     $args            {}    [in]
    * Return:    void
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    $context->init($args);

=cut

sub init {
    my ($self, $args) = @_;
}

#############################################################################
# PUBLIC METHODS
#############################################################################

=head1 Public Methods: Services

=cut

#############################################################################
# service()
#############################################################################

=head2 service()

The service() method returns a named object of a certain service type.

    * Signature: $service = $context->service($type);
    * Signature: $service = $context->service($type,$name);
    * Signature: $service = $context->service($type,$name,%named);
    * Param:  $type        string  [in]
    * Param:  $name        string  [in]
    * Return: $service     App::Service
    * Throws: App::Exception
    * Since:  0.01

    Sample Usage: 

    $user = $context->service("SessionObject","db.user.spadkins");
    $gobutton = $context->service("SessionObject","gobutton");

There are many services available within an App-Context application.
Each service is identified by two pieces of information:
it's type and its name.

The following service types are standard in App-Context.
Others can be developed by deriving a class from the
App::Service class.
All service types must start with a capital letter.

    * Serializer
    * CallDispatcher
    * MessageDispatcher
    * ResourceLocker
    * SharedDatastore
    * Authentication
    * Authorization
    * SessionObject

Within each service type, each individual service is
identified by its name.
The name of a service, if not
specified, is assumed to be "default".

Whenever a service is requested from the Context via this
service() method, the service cache in the Session is checked
first.  If it exists, it is generally returned immediately
without modification by the named parameters.
(Parameters *are* taken into account if the "override"
parameter is supplied.)

If it does not exist, it must be created and stored in the 
cache.

The name of a service, if not specified, is assumed to be "default".

The named parameters (%named or $named),
if supplied, are considered defaults.
They are ignored if the values already exist in the service conf.
However, the additional named parameter, "override", may be supplied.
In that case, all of the values in the named parameters will accepted
into the service conf.

Every service (i.e. $conf->{Repository}{default}) starts as
a simple hash which is populated with attributes from several
complementary sources.  If we imagine that a service is requested
with type $type and name $name, we can envision the following
additional derived variables.

  $type           = "Repository";
  $name           = "sysdb";
  $lcf_type       = "repository";  # lower-case first letter
  $conf           = $context->conf();
  $repositoryType = $conf->{Repository}{sysdb}{repositoryType};

The following sources are consulted to populate the service
attributes.

  1. conf of the service (in Conf)
     i.e. $conf->{Repository}{sysdb}

  2. optional conf of the service's service_type (in Conf)
     i.e. $conf->{RepositoryType}{$repositoryType}

  3. named parameters to the service() call

All service configuration happens before instantiation
this allows you to override the "serviceClass" in the configuration
in time for instantiation

=cut

sub service {
    my ($self, $type, $name, %named) = @_;
    $self->dbgprint("Context->service(" . join(", ",@_) . ")")
        if ($App::DEBUG && $self->dbg(3));

    my ($args, $lcf_type, $new_service, $override, $volatile, $attrib);
    my ($service, $conf, $class, $session);
    my ($service_store, $service_conf, $service_type, $service_type_conf);
    my ($default);

    if (!defined $type) {
        App::Exception->throw(
            error => "cannot create a service of unknown type\n",
        );
    }

    if (%named) {
        $args = \%named;
    }
    else {
        $args = {};
    }

    if (! defined $name || $name eq "") {    # we need a name!
        $name = "default";
    }

    $lcf_type = lcfirst($type);

    $session = $self->{session};
    $service = $session->{cache}{$type}{$name};  # check the cache

    $new_service = 0;

    if (!defined $service || ref($service) eq "HASH") {
        $service = {} if (!defined $service);  # start with new hash ref
        $service->{name} = $name;
        $service->{context} = $self;

        $conf          = $self->{conf};
        $service_conf  = $conf->{$type}{$name};
        $service_store = $session->{store}{$type}{$name};

        $self->dbgprint("Context->service(): new service. conf=$conf sconf=$service_conf sstore=$service_store")
            if ($App::DEBUG && $self->dbg(6));
    
        $new_service = 1;

        ################################################################
        # start with runtime store for the service from the session
        ################################################################
        if ($service_store) {
            foreach $attrib (keys %$service_store) {
                if (!defined $service->{$attrib}) {
                    $service->{$attrib} = $service_store->{$attrib};
                }
            }
        }

        ################################################################
        # overlay with attributes from the conf file
        ################################################################
        if ($service_conf) {
            foreach $attrib (keys %$service_conf) {
                # include conf attributes only if not set already
                if (!defined $service->{$attrib}) {
                    $service->{$attrib} = $service_conf->{$attrib};
                }
            }
        }

        ################################################################
        # overlay with attributes from the "service_type"
        ################################################################
        $service_type = $service->{"${lcf_type}Type"}; # i.e. "sessionObjectType"
        if ($service_type) {
            $service_type_conf = $conf->{"${type}Type"}{$service_type};
            if ($service_type_conf) {
                foreach $attrib (keys %$service_type_conf) {
                    # include service_type confs only if not set already
                    if (!defined $service->{$attrib}) {
                        $service->{$attrib} = $service_type_conf->{$attrib};
                    }
                }
            }
        }
    }

    ################################################################
    # take care of all %$args attributes next
    ################################################################

    # A "volatile" service is one which never stores its attributes in
    # the session store.  It assumes that all necessary attributes will
    # be supplied by the conf or by the code.  As a result, a "volatile"
    # service can usually never handle events.
    #   1. its attributes are only ever required when they are all supplied
    #   2. its attributes will be OK by combining the %$args with the %$conf
    #      and %$store.
    # This all saves space in the Session store, as the attribute values can
    # be relied upon to be supplied by the conf file and the code (and
    # minimal reliance on the Session store).
    # This is really handy when you have something like a huge spreadsheet
    # of text entry cells (usually an indexed variable).

    if (defined $args->{volatile}) {          # may be specified explicitly
        $volatile = $args->{volatile};
    }
    else {
        $volatile = ($name =~ /[\{\}\[\]]/);  # or implicitly for indexed variables
    }
    $override = $args->{override};

    if ($new_service || $override) {
        foreach $attrib (keys %$args) {
            # don't include the entry which says whether we are overriding or not
            next if ($attrib eq "override");

            # include attrib if overriding OR attrib not provided in the session_object confs already
            if (!defined $service->{$attrib} ||
                ($override && $service->{$attrib} ne $args->{$attrib})) {
                $service->{$attrib} = $args->{$attrib};
                $session->{store}{$type}{$name}{$attrib} = $args->{$attrib} if (!$volatile);
            }
            $self->dbgprint("Context->service() [arg=$attrib] name=$name vol=$volatile ovr=$override",
                " service=", $service->{$attrib},
                " service_store=", $service_store->{$attrib},
                " args=", $args->{$attrib})
                if ($App::DEBUG && $self->dbg(6));
        }
    }
 
    if ($new_service) {
        $self->dbgprint("Context->service() new service [$name]")
            if ($App::DEBUG && $self->dbg(3));

        if (defined $service->{default}) {
            $default = $service->{default};
            if ($default eq "{today}") {
                $default = time2str("%Y-%m-%d",time);
            }
            $self->so_get($name, "", $default, 1);
            #if ($name =~ /^(.+)\.([^.]+)$/) {
            #    $self->so_get($1, $2, $default, 1);
            #}
            #else {
            #    $self->so_get("default", $name, $default, 1);
            #}
            $self->so_delete($name, "default");
        }

        $class = $service->{"${lcf_type}Class"};      # find class of service

        if (!defined $class || $class eq "") {      # error if no class given
            $class = "App::$type";   # assume the "generic" class
            $service->{"${lcf_type}Class"} = $class;
            #if ($name eq "default") {
            #    $class = "App::$type";   # assume the "generic" class
            #}
            #else {
            #    App::Exception->throw(
            #        error => "no class was configured for the \"$type\" named \"$name\"\n",
            #    );
            #}
        }

        if (! $self->{used}{$class}) {                        # load the code
            App->use($class);
            $self->{used}{$class} = 1;
        }

        bless $service, $class;            # bless the service into the class
        $session->{cache}{$type}{$name} = $service;       # save in the cache
        $service->init();                # perform additional initializations
    }

    $self->dbgprint("Context->service() = $service")
        if ($App::DEBUG && $self->dbg(3));

    return $service;
}

#############################################################################
# service convenience methods
#############################################################################

=head2 serializer()

=head2 call_dispatcher()

=head2 message_dispatcher()

=head2 resource_locker()

=head2 shared_datastore()

=head2 authentication()

=head2 authorization()

=head2 session_object()

These are all convenience methods, which simply turn around
and call the service() method with the service type as the
first argument.

    * Signature: $session = $context->session();
    * Signature: $session = $context->session($name);
    * Signature: $session = $context->session($name,%named);
    * Param:  $name        string  [in]
    * Return: $service     App::Service
    * Throws: App::Exception
    * Since:  0.01

    Sample Usage: 

    $serializer          = $context->serializer();
    $call_dispatcher     = $context->call_dispatcher();
    $message_dispatcher  = $context->message_dispatcher();
    $resource_locker     = $context->resource_locker();
    $shared_datastore    = $context->shared_datastore();
    $authentication      = $context->authentication();
    $authorization       = $context->authorization();
    $session_object      = $context->session_object();

=cut

sub serializer          { my $self = shift; return $self->service("Serializer",@_); }
sub call_dispatcher     { my $self = shift; return $self->service("CallDispatcher",@_); }
sub message_dispatcher  { my $self = shift; return $self->service("MessageDispatcher",@_); }
sub resource_locker     { my $self = shift; return $self->service("ResourceLocker",@_); }
sub shared_datastore    { my $self = shift; return $self->service("SharedDatastore",@_); }
sub authentication      { my $self = shift; return $self->service("Authentication",@_); }
sub authorization       { my $self = shift; return $self->service("Authorization",@_); }
sub session_object      { my $self = shift; return $self->service("SessionObject",@_); }

#############################################################################
# session_object_exists()
#############################################################################

=head2 session_object_exists()

    * Signature: $exists = $context->session_object_exists($session_object_name);
    * Param:  $session_object_name     string
    * Return: $exists          boolean
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    if ($context->session_object_exists($session_object_name)) {
        # do something
    }

The session_object_exists() returns whether or not a session_object is already known to the
Context.  This is true if 

 * it exists in the Session's session_object cache, or
   (i.e. it has already been referenced and instantiated in the cache),
 * it exists in the Session's store, or
   (i.e. it was referenced in an earlier request in this session)
 * it exists in the Conf

If this method returns FALSE (undef), then any call to the session_object() method
must specify the session_objectClass (at a minimum) and may not simply call it
with the $session_object_name.

This is useful particularly for volatile session_objects which generate events
(such as image buttons).  The $context->dispatch_events() method can check
that the session_object has not yet been defined and automatically passes the
event to the session_object's container (implied by the name) for handling.

=cut

sub session_object_exists {
    my ($self, $session_object_name) = @_;
    my ($exists, $session_object_type, $session_object_class);

    $session_object_class =
        $self->{session}{cache}{SessionObject}{$session_object_name}{session_objectClass} ||
        $self->{session}{store}{SessionObject}{$session_object_name}{session_objectClass} ||
        $self->{conf}{SessionObject}{$session_object_name}{session_objectClass};

    if (!$session_object_class) {

        $session_object_type =
            $self->{session}{cache}{SessionObject}{$session_object_name}{session_objectType} ||
            $self->{session}{store}{SessionObject}{$session_object_name}{session_objectType} ||
            $self->{conf}{SessionObject}{$session_object_name}{session_objectType};

        if ($session_object_type) {
            $session_object_class = $self->{conf}{SessionObjectType}{$session_object_type}{session_objectClass};
        }
    }

    $exists = $session_object_class ? 1 : 0;

    $self->dbgprint("Context->session_object_exists($session_object_name) = $exists")
        if ($App::DEBUG && $self->dbg(2));

    return $exists;
}

#############################################################################
# PUBLIC METHODS
#############################################################################

=head1 Public Methods: Accessors

=cut

#############################################################################
# iget()
#############################################################################

=head2 iget()

    * Signature: $value = $context->iget($var, $default);
    * Param:  $var             string
    * Param:  $attribute       string
    * Return: $value           string
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    $script_url_dir = $context->iget("scriptUrlDir", "/cgi-bin");

The iget() returns the value of an Initialization Conf variable
(or the "default" value if not set).

This is an alternative to 
getting the reference of the entire hash of Initialization Conf
variables with $self->initconf().

=cut

sub iget {
    my ($self, $var, $default) = @_;
    my $value = $self->{initconf}{$var};
    $self->dbgprint("Context->iget($var) = [$value]")
        if ($App::DEBUG && $self->dbg(3));
    return (defined $value) ? $value : $default;
}

#############################################################################
# so_get()
#############################################################################

=head2 so_get()

The so_get() returns the attribute of a session_object.

    * Signature: $value = $context->so_get($session_objectname, $attribute);
    * Param:  $session_objectname      string
    * Param:  $attribute       string
    * Return: $value           string,ref
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    $cname = $context->so_get("default", "cname");
    $width = $context->so_get("main.app.toolbar.calc", "width");

=cut

sub so_get {
    my ($self, $name, $var, $default, $setdefault) = @_;
    my ($perl, $value);

    if (!defined $var || $var eq "") {
        if ($name =~ /^([a-zA-Z0-9_\.-]+)([\{\}\[\]].*)$/) {
            $name = $1;
            $var = $2;
        }
        elsif ($name =~ /^([a-zA-Z0-9_\.-]+)\.([a-zA-Z0-9_]+)$/) {
            $name = $1;
            $var = $2;
        }
        else {
            $var  = $name;
            $name = "default";
        }
    }

    if ($var !~ /[\[\]\{\}]/) {         # no special chars, "foo.bar"
        $value = $self->{session}{cache}{SessionObject}{$name}{$var};
        if (!defined $value && defined $default) {
            $value = $default;
            if ($setdefault) {
                $self->{session}{store}{SessionObject}{$name}{$var} = $value;
                $self->session_object($name) if (!defined $self->{session}{cache}{SessionObject}{$name});
                $self->{session}{cache}{SessionObject}{$name}{$var} = $value;
            }
        }
        $self->dbgprint("Context->so_get($name,$var) (value) = [$value]")
            if ($App::DEBUG && $self->dbg(3));
        return $value;
    } # match {
    elsif ($var =~ /^\{([^\}]+)\}$/) {  # a simple "{foo.bar}"
        $var = $1;
        $value = $self->{session}{cache}{SessionObject}{$name}{$var};
        if (!defined $value && defined $default) {
            $value = $default;
            if ($setdefault) {
                $self->{session}{store}{SessionObject}{$name}{$var} = $value;
                $self->session_object($name) if (!defined $self->{session}{cache}{SessionObject}{$name});
                $self->{session}{cache}{SessionObject}{$name}{$var} = $value;
            }
        }
        $self->dbgprint("Context->so_get($name,$var) (attrib) = [$value]")
            if ($App::DEBUG && $self->dbg(3));
        return $value;
    } # match {
    elsif ($var =~ /^[\{\}\[\]].*$/) {

        $self->session_object($name) if (!defined $self->{session}{cache}{SessionObject}{$name});

        $var =~ s/\{([^\}]+)\}/\{"$1"\}/g;
        $perl = "\$value = \$self->{session}{cache}{SessionObject}{\$name}$var;";
        eval $perl;
        $self->add_message("eval [$perl]: $@") if ($@);
        #print STDERR "ERROR: Context->get($var): eval ($perl): $@\n" if ($@);

        $self->dbgprint("Context->so_get($name,$var) (indexed) = [$value]")
            if ($P5EEx::Blue::DEBUG && $self->dbg(3));
    }

    return $value;
}

#############################################################################
# so_set()
#############################################################################

=head2 so_set()

The so_set() sets an attribute of a session_object in the Session.

    * Signature: $context->so_set($session_objectname, $attribute, $value);
    * Param:  $session_objectname      string
    * Param:  $attribute       string
    * Param:  $value           string,ref
    * Return: void
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    $context->so_set("default", "cname", "main_screen");
    $context->so_set("main.app.toolbar.calc", "width", 50);
    $context->so_set("xyz", "{arr}[1][2]",  14);
    $context->so_set("xyz", "{arr.totals}", 14);

=cut

sub so_set {
    my ($self, $name, $var, $value) = @_;
    my ($perl);

    if ($value eq "{:delete:}") {
        return $self->so_delete($name,$var);
    }

    $self->dbgprint("Context->so_set($name,$var,$value)")
        if ($App::DEBUG && $self->dbg(3));

    if (!defined $var || $var eq "") {
        if ($name =~ /^([a-zA-Z0-9_\.-]+)([\{\}\[\]].*)$/) {
            $name = $1;
            $var = $2;
        }
        elsif ($name =~ /^([a-zA-Z0-9_\.-]+)\.([a-zA-Z0-9_]+)$/) {
            $name = $1;
            $var = $2;
        }
        else {
            $var  = $name;
            $name = "default";
        }
    }

    if ($var !~ /[\[\]\{\}]/) {         # no special chars, "foo.bar"
        $self->{session}{store}{SessionObject}{$name}{$var} = $value;
        $self->{session}{cache}{SessionObject}{$name}{$var} = $value
            if (defined $self->{session}{cache}{SessionObject}{$name});
        return;
    } # match {
    elsif ($var =~ /^\{([^\}]+)\}$/) {  # a simple "{foo.bar}"
        $var = $1;
        $self->{session}{store}{SessionObject}{$name}{$var} = $value;
        $self->{session}{cache}{SessionObject}{$name}{$var} = $value
            if (defined $self->{session}{cache}{SessionObject}{$name});
        return;
    }
    elsif ($var =~ /^\{/) {  # { i.e. "{columnSelected}{first_name}"

        $var =~ s/\{([^\}]+)\}/\{"$1"\}/g;  # put quotes around hash keys

        #$self->session_object($name) if (!defined $self->{session}{cache}{SessionObject}{$name});

        $perl  = "\$self->{session}{store}{SessionObject}{\$name}$var = \$value;";
        $perl .= "\$self->{session}{cache}{SessionObject}{\$name}$var = \$value;"
            if (defined $self->{session}{cache}{SessionObject}{$name});

        eval $perl;
        $self->add_message("eval [$perl]: $@") if ($@);
        #die "ERROR: Context->so_set($name,$var,$value): eval ($perl): $@" if ($@);
    }
    # } else we do nothing with it!

    return $value;
}

#############################################################################
# so_delete()
#############################################################################

=head2 so_delete()

The so_delete() deletes an attribute of a session_object in the Session.

    * Signature: $context->so_delete($session_objectname, $attribute);
    * Param:  $session_objectname      string
    * Param:  $attribute       string
    * Return: void
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    $context->so_delete("default", "cname");
    $context->so_delete("main.app.toolbar.calc", "width");
    $context->so_delete("xyz", "{arr}[1][2]");
    $context->so_delete("xyz", "{arr.totals}");

=cut

sub so_delete {
    my ($self, $name, $var) = @_;
    my ($perl);

    $self->dbgprint("Context->so_delete($name,$var)")
        if ($App::DEBUG && $self->dbg(3));

    if (!defined $var || $var eq "") {
        if ($name =~ /^([a-zA-Z0-9_\.-]+)([\{\}\[\]].*)$/) {
            $name = $1;
            $var = $2;
        }
        elsif ($name =~ /^([a-zA-Z0-9_\.-]+)\.([a-zA-Z0-9_]+)$/) {
            $name = $1;
            $var = $2;
        }
        else {
            $var  = $name;
            $name = "default";
        }
    }

    if ($var !~ /[\[\]\{\}]/) {         # no special chars, "foo.bar"
        delete $self->{session}{store}{SessionObject}{$name}{$var};
        delete $self->{session}{cache}{SessionObject}{$name}{$var}
            if (defined $self->{session}{cache}{SessionObject}{$name});
        return;
    } # match {
    elsif ($var =~ /^\{([^\}]+)\}$/) {  # a simple "{foo.bar}"
        $var = $1;
        delete $self->{session}{store}{SessionObject}{$name}{$var};
        delete $self->{session}{cache}{SessionObject}{$name}{$var}
            if (defined $self->{session}{cache}{SessionObject}{$name});
        return;
    }
    elsif ($var =~ /^\{/) {  # { i.e. "{columnSelected}{first_name}"

        $var =~ s/\{([^\}]+)\}/\{"$1"\}/g;  # put quotes around hash keys

        #$self->session_object($name) if (!defined $self->{session}{cache}{SessionObject}{$name});

        $perl  = "delete \$self->{session}{store}{SessionObject}{\$name}$var;";
        $perl .= "delete \$self->{session}{cache}{SessionObject}{\$name}$var;"
            if (defined $self->{session}{cache}{SessionObject}{$name});

        eval $perl;
        $self->add_message("eval [$perl]: $@") if ($@);
        #die "ERROR: Context->so_delete($name,$var): eval ($perl): $@" if ($@);
    }
    # } else we do nothing with it!
}

#############################################################################
# PUBLIC METHODS
#############################################################################

=head1 Public Methods: Miscellaneous

=cut

#############################################################################
# add_message()
#############################################################################

=head2 add_message()

The add_message() method stores a string (the concatenated list of @args) in
the Context until it can be viewed by and acted upon by the user.

    * Signature: $context->add_message($msg);
    * Param:  $msg         string  [in]
    * Return: void
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    $context->add_message("Data was not saved. Try again.");

=cut

sub add_message {
    my ($self, $msg) = @_;

    $self->dbgprint("Context->add_message()\n====\n$msg====\n")
        if ($App::DEBUG && $self->dbg(1));

    if (defined $self->{messages}) {
        $self->{messages} .= "<br>\n" . $msg;
    }
    else {
        $self->{messages} = $msg;
    }
}

#############################################################################
# log()
#############################################################################

=head2 log()

The log() method writes a string (the concatenated list of @args) to
the default log channel.

    * Signature: $context->log(@args);
    * Param:  @args        string  [in]
    * Return: void
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    $context->log("oops, a bug happened");

=cut

sub log {
    my $self = shift;
    print STDERR "Log: ", @_, "\n";
}

#############################################################################
# user()
#############################################################################

=head2 user()

The user() method returns the username of the authenticated user.
The special name, "guest", refers to the unauthenticated (anonymous) user.

    * Signature: $username = $context->user();
    * Param:  void
    * Return: string
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    $username = $context->user();

=cut

sub user {
    my $self = shift;
    "guest";
}

#############################################################################
# initconf()
#############################################################################

=head2 initconf()

    * Signature: $initconf = $context->initconf();
    * Param:  void
    * Return: $initconf    {}
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    $initconf = $context->initconf();

The initconf() method returns a hashreference to all of the variable/value
pairs used in the initialization of the Context.

=cut

sub initconf {
    my $self = shift;
    $self->{initconf};
}

#############################################################################
# conf()
#############################################################################

=head2 conf()

    * Signature: $conf = $context->conf();
    * Param:  void
    * Return: $conf    App::Conf
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    $conf = $context->conf();

The conf() method returns the user's conf data structure.

=cut

sub conf {
    my $self = shift;
    $self->{conf};
}

#############################################################################
# session()
#############################################################################

=head2 session()

The session() method returns the session

    * Signature: $session = $context->session();
    * Param:  void
    * Return: $session    App::Session
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    $session = $context->session();

=cut

sub session {
    my $self = shift;
    $self->{session};
}

#############################################################################
# domain()
#############################################################################

=head2 domain()

The domain() method is called to get the list of valid values in a data
domain and the labels that should be used to represent these values to
a user.

    * Signature: ($values, $labels) = $self->domain($domain_name)
    * Param:     $domain_name      string
    * Return:    $values           []
    * Return:    $labels           {}
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    ($values, $labels) = $self->domain("gender");
    foreach (@$values) {
        print "$_ => $labels->{$_}\n";
    }

=cut

sub domain {
    my ($self, $domain) = @_;
    my ($domain_conf, $domain_session, $repository, $rep);
    my ($values, $labels, $needs_loading, $time_to_live, $time);
    my ($class, $method, $args, $rows, $row);

    $self->dbgprint("Context->domain($domain)")
        if ($App::DEBUG && $self->dbg(1));

    $domain_conf  = $self->{conf}{Domain}{$domain};
    $domain_session = $self->{session}{Domain}{$domain};
    $domain_conf  = {} if (!defined $domain_conf);
    $domain_session = {} if (!defined $domain_session);

    $values = $domain_session->{values};
    $values = $domain_conf->{values} if (!$values);

    $labels = $domain_session->{labels};
    $labels = $domain_conf->{labels} if (!$labels);

    $needs_loading = 0;
    $repository = $domain_session->{repository};
    $repository = $domain_conf->{repository} if (!$repository);

    if (defined $repository && $repository ne "") {
        if (!defined $values || !defined $labels) {
            $needs_loading = 1;
        }
        else {
            $time_to_live = $domain_conf->{time_to_live};
            if (defined $time_to_live && $time_to_live ne "" && $time_to_live >= 0) {
                if ($time_to_live == 0) {
                    $needs_loading = 1;
                }
                else {
                    if (time() >= $domain_session->{time} + $time_to_live) {
                        $needs_loading = 1;
                    }
                }
            }
        }
    }

    $self->dbgprint("Context->domain($domain): needs_loading=$needs_loading")
        if ($App::DEBUG && $self->dbg(1));

    if ($needs_loading) {
        $rep = $self->repository($repository);
        if (defined $rep) {
            #$method = $domain_session->{getmethod};
            #$method = "get" if (!defined $method);
            #$args   = $domain_session->{getmethod_args};
            #$args   = [ $domain ] if (!defined $args);

            #$self->dbgprint("Context->domain($domain): $rep->$method(@$args)")
            #    if ($App::DEBUG && $self->dbg(1));

            #$rows   = ${rep}->${method}(@$args);
            #$values = [];
            #$labels = {};
            #foreach $row (@$rows) {
            #    push(@$values, $row->[0]);
            #    $labels->{$row->[0]} = $row->[1];
            #}
            #$domain_session->{values} = $values;
            #$domain_session->{labels} = $labels;
            #$time = time();
            #$domain_session->{time} = $time;
        }

        $values = $domain_session->{values};
        $labels = $domain_session->{labels};
    }

    $values = [] if (! defined $values);
    $labels = {} if (! defined $labels);
    return ($values, $labels);
}

#############################################################################
# PUBLIC METHODS
#############################################################################

=head1 Public Methods: Debugging

=cut

#############################################################################
# dbg()
#############################################################################

=head2 dbg()

The dbg() method is used to check whether a given line of debug output
should be generated.  
It returns true or false (1 or 0).

If all three parameters are specified, this function
returns true only when the global debug level ($App::Context::DEBUG)
is at least equal to $level and when the debug scope
is set to debug this class and method.

    * Signature: $flag = $context->dbg($class,$method,$level);
    * Param:     $class       class   [in]
    * Param:     $method      string  [in]
    * Param:     $level       integer [in]
    * Return:    void
    * Throws:    App::Exception::Context
    * Since:     0.01

    Sample Usage: 

    $context->dbgprint("this is debug output")
        if ($App::DEBUG && $context->dbg(3));

    $context->dbgprint("this is debug output")
        if ($context->dbg(3));

The first usage is functionally identical to the second, but the check
of the global debug level explicitly reduces the runtime overhead to
eliminate any method calls when debugging is not turned on.

=cut

my %debugscope;

sub dbg {
    my ($self, $level) = @_;
    return 0 if (! $App::DEBUG);
    $level = 1 if (!defined $level);
    return 0 if (defined $level && $App::DEBUG < $level);
    my ($debugscope, $stacklevel);
    my ($package, $file, $line, $subroutine, $hasargs, $wantarray);
    $debugscope = (ref($self) eq "") ? \%debugscope : $self->{debugscope};
    $stacklevel = 1;
    ($package, $file, $line, $subroutine, $hasargs, $wantarray) = caller($stacklevel);
    while (defined $subroutine && $subroutine eq "(eval)") {
        $stacklevel++;
        ($package, $file, $line, $subroutine, $hasargs, $wantarray) = caller($stacklevel);
    }
    return 1 if (! defined $debugscope);
    return 1 if (! %$debugscope);
    return 1 if (defined $debugscope->{$package});
    return 1 if (defined $debugscope->{$subroutine});
    return 0;
}

#############################################################################
# dbgprint()
#############################################################################

=head2 dbgprint()

The dbgprint() method is used to produce debug output.
The output goes to an output stream which is appropriate for
the runtime context in which it is called.

    * Signature: $flag = $context->dbgprint(@args);
    * Param:     @args        string  [in]
    * Return:    void
    * Throws:    App::Exception::Context
    * Since:     0.01

    Sample Usage: 

    $context->dbgprint("this is debug output")
        if ($App::DEBUG && $context->dbg(3));

=cut

sub dbgprint {
    my $self = shift;
    my ($file);
    $file = "";
    $file = $self->{initconf}{debugfile} if (ref($self));
    if ($file) {
        $file = ">> $file" if ($self->{initconf}{debugappend});
        local(*FILE);
        if (open(main::FILE, $file)) {
            print main::FILE $$, ": ", @_, "\n";
            close(main::FILE);
        }
    }
    else {
        print STDERR "Debug: ", @_, "\n";
    }
}

#############################################################################
# dbglevel()
#############################################################################

=head2 dbglevel()

The dbglevel() method is used to set the debug level.
Setting the dbglevel to 0 turns off debugging output and is suitable
for production use.  Setting the dbglevel to 1 or higher turns on
increasingly verbose debug output.

    * Signature: $context->dbglevel($dbglevel);
    * Signature: $dbglevel = $context->dbglevel();
    * Param:     $dbglevel   integer
    * Return:    $dbglevel   integer
    * Throws:    App::Exception::Context
    * Since:     0.01

    Sample Usage: 

    $context->dbglevel(1);             # turn it on
    $context->dbglevel(0);             # turn it off
    $dbglevel = $context->dbglevel();  # get the debug level

=cut

sub dbglevel {
    my ($self, $dbglevel) = @_;
    $App::DEBUG = $dbglevel if (defined $dbglevel);
    return $App::DEBUG;
}

#############################################################################
# dbgscope()
#############################################################################

=head2 dbgscope()

The dbgscope() method is used to get the hash which determines which
debug statements are to be printed out when the debug level is set to a
positive number.  It returns a hash reference.  If class names or
"class.method" names are defined in the hash, it will cause the
debug statements from those classes or methods to be printed.

    * Signature: $dbgscope = $context->dbgscope();
    * Param:     void
    * Return:    $dbgscope   {}
    * Throws:    App::Exception::Context
    * Since:     0.01

    Sample Usage: 

    $dbgscope = $context->dbgscope();
    $dbgscope->{"App::Context::CGI"} = 1;
    $dbgscope->{"App::Context::CGI.process_request"} = 1;

=cut

sub dbgscope {
    my $self = shift;
    my $dbgscope = $self->{dbgscope};
    if (!defined $dbgscope) {
        $dbgscope = {};
        $self->{dbgscope} = $dbgscope;
    }
    $dbgscope;
}

#############################################################################
# dump()
#############################################################################

=head2 dump()

    * Signature: $perl = $context->dump();
    * Param:     void
    * Return:    $perl      text
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    print $self->dump(), "\n";

=cut

use Data::Dumper;

sub dump {
    my ($self) = @_;
    my $d = Data::Dumper->new([ $self ], [ "context" ]);
    $d->Indent(1);
    return $d->Dump();
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

The dispatch_events() method is called by the bootstrap environmental code
in order to get the Context object rolling.  It causes the program to block
(wait on I/O), loop, or poll, in order to find events from the environment
and dispatch them to the appropriate places within the App-Context framework.

It is considered "protected" because no classes should be calling it.

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
    App::Exception->throw (
        error => "dispatch_events(): unimplemented\n",
    );
}

#############################################################################
# shutdown()
#############################################################################

=head2 shutdown()

The shutdown() method is called when the Context is preparing to exit.
This allows for connections to databases, etc. to be closed gracefully.

    * Signature: $self->shutdown()
    * Param:     void
    * Return:    void
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    $self->shutdown();

=cut

sub shutdown {
    my $self = shift;
    my ($conf, $repdef, $repname, $instance);
    my ($class, $method, $args, $argidx, $repcache);

    $self->dbgprint("Context->shutdown()")
        if ($App::DEBUG && $self->dbg(1));

    $repcache = $self->{session}{cache}{Repository};
    if (defined $repcache && ref($repcache) eq "HASH") {
        foreach $repname (keys %$repcache) {
            $instance = $repcache->{$repname};
       
            $self->dbgprint("Context->shutdown(): $instance->disconnect()")
                if ($App::DEBUG && $self->dbg(1));
     
            $instance->disconnect();
            delete $repcache->{$repname};
        }
    }
}

1;

