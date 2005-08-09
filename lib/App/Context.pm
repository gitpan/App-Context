
#############################################################################
## $Id: Context.pm,v 1.21 2005/08/09 19:11:17 spadkins Exp $
#############################################################################

package App::Context;

use strict;

use App;

use Date::Format;

=head1 NAME

App::Context - an application development framework which allows application logic to be written which will run in a variety of runtime application contexts (web app, cmdline utility, server program, daemon, etc.)

=head1 SYNOPSIS

   # ... official way to get a Context object ...
   use App;
   $context = App->context();
   $context->dispatch_events();     # dispatch events
   $conf = $context->conf();        # get the configuration

   # any of the following named parameters may be specified
   $context = App->context(
       context_class => "App::Context::CGI",
       conf_class => "App::Conf::File",   # or any Conf args
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
 $context->{debug_scope}{$class}          Debugging all methods in class
 $context->{debug_scope}{$class.$method}  Debugging a single method
 $context->{options}    Args that Context was created with
 $context->{used}{$class}  Similar to %INC, keeps track of what classes used
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

    * Signature: $context = App->new($named);
    * Signature: $context = App->new(%named);
    * Param:  context_class class  [in]
    * Param:  conf_class    class  [in]
    * Param:  conf_file     string [in]
    * Return: $context     App::Context
    * Throws: Exception::Class::Context
    * Since:  0.01

    Sample Usage: 

    $context = App::Context->new();
    $context = App::Context->new( {
        conf_class  => 'App::Conf::File',
        conf_file   => 'app.xml',
    } );
    $context = App::Context->new(
        conf_class  => 'App::Conf::File',
        conf_file   => 'app.xml',
    );

=cut

sub new {
    &App::sub_entry if ($App::trace);
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless $self, $class;

    my ($options, %options, $i);
    if ($#_ > -1) {
        if (ref($_[0]) eq "HASH") {
            $options = shift;
            die "Odd number of named args in App::Context->new()"
                if ($#_ % 2 == 0);
            for ($i = 0; $i < $#_; $i++) {
                $options->{$_[$i]} = $_[$i+1];
            }
        }
        else {
            $options = ($#_ > -1) ? { @_ } : {};
        }
    }
    %options = %$options;

    #################################################################
    # DEBUGGING
    #################################################################

    # Supports the following command-line usage:
    #    -debug=1                                      (global debug)
    #    -debug=1,App::Context                     (debug class only)
    #    -debug=3,App::Context,App::Session        (multiple classes)
    #    -debug=6,App::Repository::DBI.select_rows   (indiv. methods)
    my ($debug, $pkg);
    $debug = $options{debug};
    if (defined $debug && $debug ne "") {
        if ($debug =~ s/^([0-9]+),?//) {
            $App::DEBUG = $1;
        }
        if ($debug) {
            foreach $pkg (split(/,/,$debug)) {
                $self->{debug_scope}{$pkg} = 1;
            }
        }
    }

    my ($conf_class, $session_class);
    $self->{options} = \%options;
    $options{context} = $self;

    $conf_class   = $options{conf_class};
    $conf_class   = "App::Conf::File" if (! $conf_class);

    if ($App::DEBUG >= 2) {
        my (@str, $key);
        push(@str,"Context->new(): conf=$conf_class\n");
        foreach $key (sort keys %options) {
            push(@str, "   $key => $options{$key}\n");
        }
        $self->dbgprint(join("",@str));
    }

    my $conf = {};
    eval {
        $conf = App->new($conf_class, "new", \%options);
        foreach my $var (keys %options) {
            if ($var =~ /^app\.(.+)/) {
                $conf->set($1, $options{$var});
            }
        }
    };
    $self->add_message($@) if ($@);
    $self->{conf} = $conf;

    if ($options{debug_conf} >= 2) {
        $self->dbgprint($self->{conf}->dump());
    }

    $self->{events} = [];      # the event queue starts empty
    $self->{returntype} = "default";  # assume default return type

    $self->{scheduled_events} = [];
    $self->{scheduled_event} = {};

    $self->_init(\%options);   # allows the subclass to do initialization

    $self->set_current_session($self->session("default"));

    &App::sub_exit($self) if ($App::trace);
    return $self;
}

sub _default_session_class {
    &App::sub_entry if ($App::trace);
    &App::sub_exit("App::Session") if ($App::trace);
    return("App::Session");
}

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

The _init() method is called from within the standard Context constructor.
The _init() method in this class does nothing.
It allows subclasses of the Context to customize the behavior of the
constructor by overriding the _init() method. 

    * Signature: $context->_init($options)
    * Param:     $options          {}    [in]
    * Return:    void
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    $context->_init($options);

=cut

sub _init {
    &App::sub_entry if ($App::trace);
    my ($self, $options) = @_;
    &App::sub_exit() if ($App::trace);
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
  $conf           = $context->conf();
  $repository_type = $conf->{Repository}{sysdb}{repository_type};

The following sources are consulted to populate the service
attributes.

  1. conf of the service (in Conf)
     i.e. $conf->{Repository}{sysdb}

  2. optional conf of the service's service_type (in Conf)
     i.e. $conf->{RepositoryType}{$repository_type}

  3. named parameters to the service() call

All service configuration happens before instantiation
this allows you to override the "service_class" in the configuration
in time for instantiation

=cut

sub service {
    &App::sub_entry if ($App::trace);
    my ($self, $type, $name, %named) = @_;
    $self->dbgprint("Context->service(" . join(", ",@_) . ")")
        if ($App::DEBUG && $self->dbg(3));

    my ($args, $new_service, $override, $lightweight, $attrib);
    my ($service, $conf, $class, $session);
    my ($service_store, $service_conf, $service_type, $service_type_conf);
    my ($default);

    # $type (i.e. SessionObject, Session, etc.) must be supplied
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

    $session = $self->{session};
    $service = $session->{cache}{$type}{$name};  # check the cache

    ##############################################################
    # Load extra conf on demand
    ##############################################################
    $conf = $self->{conf};
    $service_conf = $conf->{$type}{$name};
    if (!$service_conf) {
        my $options = $self->{options};
        my $prefix = $options->{prefix};
        my $conf_type = $options->{conf_type} || "pl";
        my $conf_file = "$prefix/etc/app/$type.$name.$conf_type";
        if (-r $conf_file) {
            $service_conf = App::Conf::File->create({ conf_file => $conf_file });
            $conf->{$type}{$name} = $service_conf;
        }
    }

    ##############################################################
    # aliases
    ##############################################################
    if (defined $service_conf) {
        my $alias = $service_conf->{alias};
        if ($alias) {
            $name = $alias;
            $service = $session->{cache}{$type}{$name};
            $service_conf = $conf->{$type}{$name};
        }
    }

    $new_service = 0;

    #   NEVER DEFINED     OR   NON-BLESSED HASH (fully defined services are blessed into classes)
    if (!defined $service || ref($service) eq "HASH") {
        $service = {} if (!defined $service);  # start with new hash ref
        $service->{name} = $name;
        $service->{context} = $self;

        $service_store = $session->{store}{$type}{$name};

        if ($App::DEBUG && $self->dbg(6)) {
            $self->dbgprint("Context->service(): new service. conf=$conf svc=$service sconf=$service_conf sstore=$service_store");
            $self->dbgprint("Context->service():              sconf={",join(",",%$service_conf),"}") if ($service_conf);
            $self->dbgprint("Context->service():              sstore={",join(",",%$service_store),"}") if ($service_store);
        }
    
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
        $service_type = $service->{type}; # i.e. "session_object_type"
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

    # A "lightweight" service is one which never stores its attributes in
    # the session store.  It assumes that all necessary attributes will
    # be supplied by the conf or by the code.  As a result, a "lightweight"
    # service can usually never handle events.
    #   1. its attributes are only ever required when they are all supplied
    #   2. its attributes will be OK by combining the %$args with the %$conf
    # This all saves space in the Session store, as the attribute values can
    # be relied upon to be supplied by the conf file and the code (and
    # minimal reliance on the Session store).
    # This is really handy when you have something like a huge spreadsheet
    # of text entry cells (usually an indexed variable).

    if (defined $args->{lightweight}) {          # may be specified explicitly
        $lightweight = $args->{lightweight};
    }
    else {
        $lightweight = ($name =~ /[\{\}\[\]]/);  # or implicitly for indexed variables
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
                $session->{store}{$type}{$name}{$attrib} = $args->{$attrib} if (!$lightweight);
            }
            $self->dbgprint("Context->service() [arg=$attrib] name=$name lw=$lightweight ovr=$override",
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
            if (defined $default) {
                $self->so_get($name, "", $default, 1);
                $self->so_delete($name, "default");
            }
        }

        $class = $service->{class};      # find class of service

        if (!defined $class || $class eq "") {
            $class = "App::$type";   # assume the "generic" class
            $service->{class} = $class;
        }

        if (! $self->{used}{$class}) {                        # load the code
            App->use($class);
            $self->{used}{$class} = 1;
        }
        $self->dbgprint("Context->service() service class [$class]")
            if ($App::DEBUG && $self->dbg(3));

        bless $service, $class;            # bless the service into the class
        $session->{cache}{$type}{$name} = $service;       # save in the cache
        $service->_init();                # perform additional initializations
    }

    $self->dbgprint("Context->service() = $service")
        if ($App::DEBUG && $self->dbg(3));

    &App::sub_exit($service) if ($App::trace);
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
    $value_domain        = $context->value_domain();

=cut

# Standard Services: provided in the App-Context distribution
sub serializer          { my $self = shift; return $self->service("Serializer",@_); }
sub call_dispatcher     { my $self = shift; return $self->service("CallDispatcher",@_); }
sub message_dispatcher  { my $self = shift; return $self->service("MessageDispatcher",@_); }
sub resource_locker     { my $self = shift; return $self->service("ResourceLocker",@_); }
sub shared_datastore    { my $self = shift; return $self->service("SharedDatastore",@_); }
sub authentication      { my $self = shift; return $self->service("Authentication",@_); }
sub authorization       { my $self = shift; return $self->service("Authorization",@_); }
sub session_object      { my $self = shift; return $self->service("SessionObject",@_); }
sub value_domain        { my $self = shift; return $self->service("ValueDomain",@_); }

# Extended Services: provided in the App-Widget and App-Repository distributions
# this is kind of cheating for the core to know about the extensions, but OK
sub widget              { my $self = shift; return $self->service("SessionObject",@_); }
sub template_engine     { my $self = shift; return $self->service("TemplateEngine",@_); }
sub repository          { my $self = shift; return $self->service("Repository",@_); }

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
must specify the session_object_class (at a minimum) and may not simply call it
with the $session_object_name.

This is useful particularly for lightweight session_objects which generate events
(such as image buttons).  The $context->dispatch_events() method can check
that the session_object has not yet been defined and automatically passes the
event to the session_object's container (implied by the name) for handling.

=cut

sub session_object_exists {
    &App::sub_entry if ($App::trace);
    my ($self, $session_object_name) = @_;
    my ($exists, $session_object_type, $session_object_class);

    $session_object_class =
        $self->{session}{cache}{SessionObject}{$session_object_name}{session_object_class} ||
        $self->{session}{store}{SessionObject}{$session_object_name}{session_object_class} ||
        $self->{conf}{SessionObject}{$session_object_name}{session_object_class};

    if (!$session_object_class) {

        $session_object_type =
            $self->{session}{cache}{SessionObject}{$session_object_name}{session_object_type} ||
            $self->{session}{store}{SessionObject}{$session_object_name}{session_object_type} ||
            $self->{conf}{SessionObject}{$session_object_name}{session_object_type};

        if ($session_object_type) {
            $session_object_class = $self->{conf}{SessionObjectType}{$session_object_type}{session_object_class};
        }
    }

    $exists = $session_object_class ? 1 : 0;

    $self->dbgprint("Context->session_object_exists($session_object_name) = $exists")
        if ($App::DEBUG && $self->dbg(2));

    &App::sub_exit($exists) if ($App::trace);
    return $exists;
}

#############################################################################
# PUBLIC METHODS
#############################################################################

=head1 Public Methods: Accessors

=cut

#############################################################################
# get_option()
#############################################################################

=head2 get_option()

    * Signature: $value = $context->get_option($var, $default);
    * Param:  $var             string
    * Param:  $attribute       string
    * Return: $value           string
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    $script_url_dir = $context->get_option("scriptUrlDir", "/cgi-bin");

The get_option() returns the value of an Option variable
(or the "default" value if not set).

This is an alternative to 
getting the reference of the entire hash of Option
variables with $self->options().

=cut

sub get_option {
    &App::sub_entry if ($App::trace);
    my ($self, $var, $default) = @_;
    my $value = $self->{options}{$var};
    $value = $default if (!defined $value);
    &App::sub_exit($value) if ($App::trace);
    return($value);
}

#############################################################################
# so_get()
#############################################################################

=head2 so_get()

The so_get() returns the attribute of a session_object.

    * Signature: $value = $context->so_get($session_objectname, $attribute);
    * Signature: $value = $context->so_get($session_objectname, $attribute, $default);
    * Signature: $value = $context->so_get($session_objectname, $attribute, $default, $setdefault);
    * Param:  $session_objectname      string
    * Param:  $attribute               string
    * Param:  $default                 any
    * Param:  $setdefault              boolean
    * Return: $value                   string,ref
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    $cname = $context->so_get("default", "cname");
    $width = $context->so_get("main.app.toolbar.calc", "width");

=cut

sub so_get {
    &App::sub_entry if ($App::trace);
    my ($self, $name, $var, $default, $setdefault) = @_;
    my ($perl, $value);

    if (!defined $var || $var eq "") {
        if ($name =~ /^([a-zA-Z0-9_\.-]+)([\{\}\[\]].*)$/) {
            $name = $1;
            $var = $2;
        }
        elsif ($name =~ /^([a-zA-Z0-9_\.-]+)-([a-zA-Z0-9_]+)$/) {
            $name = $1;
            $var = $2;
        }
        else {
            $var  = $name;
            $name = "default";
        }
    }

    if ($var !~ /[\[\]\{\}]/) {         # no special chars, "foo-bar"
        my $cached_service = $self->{session}{cache}{SessionObject}{$name};
        if (!defined $cached_service || ref($cached_service) eq "HASH") {
            $cached_service = $self->session_object($name);
        }
        $value = $cached_service->{$var};
        if (!defined $value && defined $default) {
            $value = $default;
            if ($setdefault) {
                $self->{session}{store}{SessionObject}{$name}{$var} = $value;
                $self->{session}{cache}{SessionObject}{$name}{$var} = $value;
            }
        }
        $self->dbgprint("Context->so_get($name,$var) (value) = [$value]")
            if ($App::DEBUG && $self->dbg(3));
    }
    elsif ($var =~ /^\{([^\{\}]+)\}$/) {  # a simple "{foo-bar}"
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
    }
    elsif ($var =~ /^[\{\}\[\]].*$/) {

        $self->session_object($name) if (!defined $self->{session}{cache}{SessionObject}{$name});

        $var =~ s/\{([^\{\}]+)\}/\{"$1"\}/g;
        $perl = "\$value = \$self->{session}{cache}{SessionObject}{\$name}$var;";
        eval $perl;
        $self->add_message("eval [$perl]: $@") if ($@);
        #print STDERR "ERROR: Context->get($var): eval ($perl): $@\n" if ($@);

        $self->dbgprint("Context->so_get($name,$var) (indexed) = [$value]")
            if ($App::DEBUG && $self->dbg(3));
    }

    &App::sub_exit($value) if ($App::trace);
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
    &App::sub_entry if ($App::trace);
    my ($self, $name, $var, $value) = @_;

    my ($perl, $retval);

    if ($value eq "{:delete:}") {
        $retval = $self->so_delete($name,$var);
    }
    else {
        $self->dbgprint("Context->so_set($name,$var,$value)")
            if ($App::DEBUG && $self->dbg(3));

        if (!defined $var || $var eq "") {
            if ($name =~ /^([a-zA-Z0-9_\.-]+)([\{\}\[\]].*)$/) {
                $name = $1;
                $var = $2;
            }
            elsif ($name =~ /^([a-zA-Z0-9_\.-]+)-([a-zA-Z0-9_]+)$/) {
                $name = $1;
                $var = $2;
            }
            else {
                $var  = $name;
                $name = "default";
            }
        }

        if ($var !~ /[\[\]\{\}]/) {         # no special chars, "foo-bar"
            $self->{session}{store}{SessionObject}{$name}{$var} = $value;
            $self->{session}{cache}{SessionObject}{$name}{$var} = $value;
                # ... we used to only set the cache attribute when the
                # object was already in the cache.
                # if (defined $self->{session}{cache}{SessionObject}{$name});
            $retval = 1;
        } # match {
        elsif ($var =~ /^\{([^\}]+)\}$/) {  # a simple "{foo-bar}"
            $var = $1;
            $self->{session}{store}{SessionObject}{$name}{$var} = $value;
            $self->{session}{cache}{SessionObject}{$name}{$var} = $value
                if (defined $self->{session}{cache}{SessionObject}{$name});
            $retval = 1;
        }
        elsif ($var =~ /^\{/) {  # { i.e. "{columnSelected}{first_name}"
    
            $var =~ s/\{([^\}]+)\}/\{"$1"\}/g;  # put quotes around hash keys
    
            #$self->session_object($name) if (!defined $self->{session}{cache}{SessionObject}{$name});
    
            $perl  = "\$self->{session}{store}{SessionObject}{\$name}$var = \$value;";
            $perl .= "\$self->{session}{cache}{SessionObject}{\$name}$var = \$value;"
                if (defined $self->{session}{cache}{SessionObject}{$name});
    
            eval $perl;
            if ($@) {
                $self->add_message("eval [$perl]: $@");
                $retval = 0;
            }
            else {
                $retval = 1;
            }
            #die "ERROR: Context->so_set($name,$var,$value): eval ($perl): $@" if ($@);
        }
        # } else we do nothing with it!
    }

    &App::sub_exit($retval) if ($App::trace);
    return $retval;
}

#############################################################################
# so_default()
#############################################################################

=head2 so_default()

The so_default() sets the value of a SessionObject's attribute
only if it is currently undefined.

    * Signature: $value = $context->so_default($session_objectname, $attribute);
    * Param:  $session_objectname      string
    * Param:  $attribute       string
    * Return: $value           string,ref
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    $cname = $context->so_default("default", "cname");
    $width = $context->so_default("main.app.toolbar.calc", "width");

=cut

sub so_default {
    &App::sub_entry if ($App::trace);
    my ($self, $name, $var, $default) = @_;
    $self->so_get($name, $var, $default, 1);
    &App::sub_exit() if ($App::trace);
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
    $context->so_delete("main-app-toolbar-calc", "width");
    $context->so_delete("xyz", "{arr}[1][2]");
    $context->so_delete("xyz", "{arr.totals}");

=cut

sub so_delete {
    &App::sub_entry if ($App::trace);
    my ($self, $name, $var) = @_;
    my ($perl);

    $self->dbgprint("Context->so_delete($name,$var)")
        if ($App::DEBUG && $self->dbg(3));

    if (!defined $var || $var eq "") {
        if ($name =~ /^([a-zA-Z0-9_\.-]+)([\{\}\[\]].*)$/) {
            $name = $1;
            $var = $2;
        }
        elsif ($name =~ /^([a-zA-Z0-9_\.-]+)-([a-zA-Z0-9_]+)$/) {
            $name = $1;
            $var = $2;
        }
        else {
            $var  = $name;
            $name = "default";
        }
    }

    if ($var !~ /[\[\]\{\}]/) {         # no special chars, "foo-bar"
        delete $self->{session}{store}{SessionObject}{$name}{$var};
        delete $self->{session}{cache}{SessionObject}{$name}{$var}
            if (defined $self->{session}{cache}{SessionObject}{$name});
    } # match {
    elsif ($var =~ /^\{([^\}]+)\}$/) {  # a simple "{foo-bar}"
        $var = $1;
        delete $self->{session}{store}{SessionObject}{$name}{$var};
        delete $self->{session}{cache}{SessionObject}{$name}{$var}
            if (defined $self->{session}{cache}{SessionObject}{$name});
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
    &App::sub_exit() if ($App::trace);
}

#############################################################################
# substitute()
#############################################################################

=head2 substitute()

The substitute() method substitutes values of SessionObjects into target strings.

    * Signature: $context->substitute($session_objectname, $attribute);
    * Param:  $session_objectname      string
    * Param:  $attribute       string
    * Return: void
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    $context->substitute("default", "cname");
    $context->substitute("main.app.toolbar.calc", "width");
    $context->substitute("xyz", "{arr}[1][2]");
    $context->substitute("xyz", "{arr.totals}");

=cut

sub substitute {
    &App::sub_entry if ($App::trace);
    my ($self, $text, $values) = @_;
    $self->dbgprint("Context->substitute()")
        if ($App::DEBUG && $self->dbg(1));
    my ($phrase, $var, $value);
    $values = {} if (! defined $values);

    if (ref($text) eq "HASH") {
        my ($hash, $newhash);
        $hash = $text;    # oops, not text, but a hash of text values
        $newhash = {};    # prepare a new hash for the substituted values
        foreach $var (keys %$hash) {
            $newhash->{$var} = $self->substitute($hash->{$var}, $values);
        }
        return($newhash); # short-circuit this whole process
    }

    while ( $text =~ /\[([^\[\]]+)\]/ ) {
        $phrase = $1;
        while ( $phrase =~ /\{([^\{\}]+)\}/ ) {
            $var = $1;
            if (defined $values->{$var}) {
                $value = $values->{$var};
                $phrase =~ s/\{$var\}/$value/g;
            }
            else {
                if ($var =~ /^(.+)\.([^.]+)$/) {
                    $value = $self->so_get($1, $2);
                    if (defined $value) {
                        $phrase =~ s/\{$var\}/$value/g;
                    }
                    else {
                        $phrase = "";
                    }
                }
                else {
                    $phrase = "";
                }
            }
        }
        if ($phrase eq "") {
            $text =~ s/\[[^\[\]]+\]\n?//;  # zap it including (optional) ending newline
        }
        else {
            $text =~ s/\[[^\[\]]+\]/$phrase/;
        }
    }
    while ( $text =~ /\{([^\{\}]+)\}/ ) {  # vars of the form {var}
        $var = $1;
        if (defined $values->{$var}) {
            $value = $values->{$var};
            $text =~ s/\{$var\}/$value/g;
        }
        else {
            $value = "";
            if ($var =~ /^(.+)\.([^.]+)$/) {
                $value = $self->so_get($1, $2);
            }
        }
        $value = "" if (!defined $value);
        $text =~ s/\{$var\}/$value/g;
    }
    &App::sub_exit($text) if ($App::trace);
    $text;
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
    &App::sub_entry if ($App::trace);
    my ($self, $msg) = @_;

    if (defined $self->{messages}) {
        $self->{messages} .= "\n" . $msg;
    }
    else {
        $self->{messages} = $msg;
    }
    &App::sub_exit() if ($App::trace);
}

sub get_messages {
    &App::sub_entry if ($App::trace);
    my ($self) = @_;
    my $msgs = $self->{messages};
    delete $self->{messages} if ($msgs);
    &App::sub_exit($msgs) if ($App::trace);
    return($msgs);
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
    &App::sub_entry if ($App::trace);
    my $self = shift;
    print STDERR "[$$] ", time2str("%Y-%m-%d %H:%M:%S", time()), " ", @_;
    &App::sub_exit() if ($App::trace);
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
    &App::sub_entry if ($App::trace);
    my $self = shift;
    &App::sub_exit("guest") if ($App::trace);
    "guest";
}

#############################################################################
# options()
#############################################################################

=head2 options()

    * Signature: $options = $context->options();
    * Param:  void
    * Return: $options    {}
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    $options = $context->options();

The options() method returns a hashreference to all of the variable/value
pairs used in the initialization of the Context.

=cut

sub options {
    &App::sub_entry if ($App::trace);
    my $self = shift;
    my $options = ($self->{options} || {});
    &App::sub_exit($options) if ($App::trace);
    return($options);
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
    &App::sub_entry if ($App::trace);
    my $self = shift;
    &App::sub_exit($self->{conf}) if ($App::trace);
    $self->{conf};
}

#############################################################################
# session()
#############################################################################

=head2 session()

    * Signature: $session = $context->session();
    * Signature: $session = $context->session($session_id);
    * Param:  $session_id   string
    * Return: $session      App::Session
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    $session = $context->session();
    $session = $context->session("some_session_id");

The session() method returns the current session (if no session_id is
supplied).  If a session_id is supplied, the requested session is
instantiated if necessary and is returned.

=cut

sub session {
    &App::sub_entry if ($App::trace);
    my ($self, $session_id, $args) = @_;
    my ($session_class, $session, $options);
    if ($session_id) {
        $session = $self->{sessions}{$session_id};
    }
    else {
        $session_id = "default";
        $session = $self->{session};
    }
    if (!$session) {
        $options = $self->{options};
        $session_class = $options->{session_class} || $self->_default_session_class();

        eval {
            $self->dbgprint("Context->new(): session_class=$session_class (", join(",",%$options), ")")
                if ($App::DEBUG && $self->dbg(1));
            if (defined $args) {
                $args = { %$args };
            }
            else {
                $args = {};
            }
            $args->{context} = $self;
            $args->{name} = $session_id;
            $session = App->new($session_class, "new", $args);
            $self->{sessions}{$session_id} = $session;
        };
        $self->add_message($@) if ($@);
    }
    &App::sub_exit($session) if ($App::trace);
    return($session);
}

#sub new_session_id {
#    &App::sub_entry if ($App::trace);
#    my ($self) = @_;
#    my $session_id = "user";
#    &App::sub_exit($session_id) if ($App::trace);
#    return($session_id);
#}

sub set_current_session {
    &App::sub_entry if ($App::trace);
    my ($self, $session) = @_;
    $self->{session} = $session;
    &App::sub_exit() if ($App::trace);
}

sub restore_default_session {
    &App::sub_entry if ($App::trace);
    my ($self) = @_;
    $self->{session} = $self->{sessions}{default};
    &App::sub_exit() if ($App::trace);
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

my %debug_scope;

sub dbg {
    my ($self, $level) = @_;
    return 0 if (! $App::DEBUG);
    $level = 1 if (!defined $level);
    return 0 if (defined $level && $App::DEBUG < $level);
    my ($debug_scope, $stacklevel);
    my ($package, $file, $line, $subroutine, $hasargs, $wantarray);
    $debug_scope = (ref($self) eq "") ? \%debug_scope : $self->{debug_scope};
    $stacklevel = 1;
    ($package, $file, $line, $subroutine, $hasargs, $wantarray) = caller($stacklevel);
    while (defined $subroutine && $subroutine eq "(eval)") {
        $stacklevel++;
        ($package, $file, $line, $subroutine, $hasargs, $wantarray) = caller($stacklevel);
    }
    return 1 if (! defined $debug_scope);
    return 1 if (! %$debug_scope);
    return 1 if (defined $debug_scope->{$package});
    return 1 if (defined $debug_scope->{$subroutine});
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
    if (defined $App::options{debugfile}) {
        print App::DEBUGFILE $$, ": ", @_, "\n";
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
# debug_scope()
#############################################################################

=head2 debug_scope()

The debug_scope() method is used to get the hash which determines which
debug statements are to be printed out when the debug level is set to a
positive number.  It returns a hash reference.  If class names or
"class.method" names are defined in the hash, it will cause the
debug statements from those classes or methods to be printed.

    * Signature: $debug_scope = $context->debug_scope();
    * Param:     void
    * Return:    $debug_scope   {}
    * Throws:    App::Exception::Context
    * Since:     0.01

    Sample Usage: 

    $debug_scope = $context->debug_scope();
    $debug_scope->{"App::Context::CGI"} = 1;
    $debug_scope->{"App::Context::CGI.process_request"} = 1;

=cut

sub debug_scope {
    my $self = shift;
    my $debug_scope = $self->{debug_scope};
    if (!defined $debug_scope) {
        $debug_scope = {};
        $self->{debug_scope} = $debug_scope;
    }
    $debug_scope;
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

    * Signature: $context->dispatch_events()
    * Param:     void
    * Return:    void
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    $context->dispatch_events();

The dispatch_events() method is called by the bootstrap environmental code
in order to get the Context object rolling.  It causes the program to block
(wait on I/O), loop, or poll, in order to find events from the environment
and dispatch them to the appropriate places within the App-Context framework.

It is considered "protected" because no classes should be calling it.

=cut

sub dispatch_events {
    &App::sub_entry if ($App::trace);
    my ($self) = @_;

    $self->dispatch_events_begin();

    my $events = $self->{events};
    my ($event, $service, $name, $method, $args);
    my $results = "";
    my $show_current_session_object = 1;

    eval {
        while ($#$events > -1) {
            $event = shift(@$events);
            ($service, $name, $method, $args) = @$event;
            $results = $self->call($service, $name, $method, $args);
            $show_current_session_object = 0;
        }
        my ($type, $name);
        if ($show_current_session_object) {
            $type = $self->so_get("default","ctype","SessionObject");
            $name = $self->so_get("default","cname","default");
        }
        if ($show_current_session_object && $type && $name) {
            $results = $self->service($type, $name);
        }

        $self->send_results($results);
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

sub dispatch_events_begin {
    &App::sub_entry if ($App::trace);
    my ($self) = @_;
    &App::sub_exit() if ($App::trace);
}

sub dispatch_events_finish {
    &App::sub_entry if ($App::trace);
    my ($self) = @_;
    $self->shutdown();  # assume we won't be doing anything else (this can be overridden)
    &App::sub_exit() if ($App::trace);
}

sub call {
    &App::sub_entry if ($App::trace);
    my ($self, $service_type, $name, $method, $args) = @_;
    my ($contents, $result, $service);

    if ($service_type eq "Context") {
        $service = $self;
    }
    else {
        $service = $self->service($service_type, $name);
    }

    if (!$service) {
        $result = "Service not defined: $service_type($name)\n";
    }
    elsif (!$service->isa("App::Widget") && $method && $service->can($method)) {
        my @args = (ref($args) eq "ARRAY") ? (@$args) : $args;
        my @results = $service->$method(@args);
        if ($#results == -1) {
            $result = $service->internals();
        }
        elsif ($#results == 0) {
            $result = $results[0];
        }
        else {
            $result = \@results;
        }
    }
    elsif ($service->can("handle_event")) {
        my @args = (ref($args) eq "ARRAY") ? (@$args) : $args;
        $result = $service->handle_event($name, $method, @args);
    }
    else {
        if ($method eq "contents") {
            $result = $service;
        }
        else {
            $result = "Method not defined on Service: $service($name).$method($args)\n";
        }
    }
    &App::sub_exit($result) if ($App::trace);
    return($result);
}

#############################################################################
# send_results()
#############################################################################

=head2 send_results()

    * Signature: $context->send_results()
    * Param:     void
    * Return:    void
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    $context->send_results();

=cut

sub send_results {
    &App::sub_entry if ($App::trace);
    my ($self, $results) = @_;

    my ($serializer, $returntype);

    if (ref($results)) {
        $returntype = $self->{returntype};
        $serializer = $self->serializer($returntype);
        $results = $serializer->serialize($results);
    }

    if ($self->{messages}) {
        my $msg = $self->{messages};
        $self->{messages} = "";
        $msg =~ s/<br>/\n/g;
        print $msg, "\n";
    }
    else {
        print $results, "\n";
    }
    &App::sub_exit() if ($App::trace);
}

sub send_error {
    &App::sub_entry if ($App::trace);
    my ($self, $errmsg) = @_;
    print <<EOF;
-----------------------------------------------------------------------------
AN ERROR OCCURRED in App::Context->dispatch_events()
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
# SCHEDULED EVENTS
#############################################################################

# valid attributes:
#    REQD: method       => "do_it",
#    OPT:  tag          => "tag01",          (identifies an event.)
#    OPT:  service_type => "SessionObject",  (method is on a SessionObject rather than on the Context)
#    OPT:  name         => "prog_controller",
#    OPT:  time         => time() + 600,
#    OPT:  interval     => 600,
#    OPT:  args         => [ 1, 2, 3 ],
#    OPT:  scheduled    => 0,

sub schedule_event {
    &App::sub_entry if ($App::trace);
    my $self = shift;
    my %event = @_;

    my $scheduled_event = $self->{scheduled_event};
    my $scheduled_events = $self->{scheduled_events};

    if (! defined $event{time}) {
        $event{time} = time();
        $event{time} += $event{interval} if ($event{interval});
    }

    my $unschedule = 0;
    if (defined $event{scheduled}) {
        $unschedule = ! $event{scheduled};
        delete $event{scheduled};
    }

    die "schedule_event(): (tag or method) is a required attribute of an event" if (!$event{tag} && !$event{method});
    print "[$$] Schedule Event (", join(",",%event), ")\n" if ($self->{verbose} >= 3);

    my $event;
    if ($event{tag}) {
        $event = $scheduled_event->{$event{tag}};
    }
    if ($event) {
        foreach my $key (keys %event) {
            $event->{$key} = $event{$key};
        }
    }
    else {
        $scheduled_event->{$event{tag}} = \%event if ($event{tag});
        $event = \%event;
    }

    if ($event->{scheduled}) {
        if ($unschedule && $event->{tag}) {
            # remove from list of scheduled events
            for (my $i = $#$scheduled_events; $i >= 0; $i--) {
                if ($scheduled_events->[$i]{tag} eq $event->{tag}) {
                    splice(@$scheduled_events, $i, 1); # remove the event
                    $event->{scheduled} = 0;
                    last;
                }
            }
        }
    }
    else {
        if (!$unschedule) {
            push(@$scheduled_events, $event);
            $event->{scheduled} = 1;
        }
    }

    &App::sub_exit() if ($App::trace);
}

sub get_current_events {
    &App::sub_entry if ($App::trace);
    my ($self, $events, $time) = @_;
    $time = time() if (!$time);
    my $time_of_next_event = 0;
    @$events = ();
    my $scheduled_event  = $self->{scheduled_event};
    my $scheduled_events = $self->{scheduled_events};
    my $verbose          = $self->{verbose};
    my ($event);
    # note: go in reverse order so that the splice() doesn't throw our indexes off
    # we do unshift() to keep events executing in FIFO order for a particular time
    for (my $i = $#$scheduled_events; $i >= 0; $i--) {
        $event = $scheduled_events->[$i];
        print "[$$] Checking event: time=$time [$event->{time}, every $event->{interval}] $event->{method}().\n" if ($verbose >= 9);
        if ($event->{time} <= $time) {
            unshift(@$events, $event);
            if ($event->{time} && $event->{interval}) {
                $event->{time} += $event->{interval}; # reschedule the event
                print "[$$] Event Rescheduled: time=$time [$event->{time}, every $event->{interval}] $event->{method}().\n" if ($verbose >= 9);
                if ($time_of_next_event == 0 || $event->{time} < $time_of_next_event) {
                    $time_of_next_event = $event->{time};
                }
            }
            else {
                print "[$$] Event Removed: time=$time [$event->{time}, every $event->{interval}] $event->{method}().\n" if ($verbose >= 9);
                splice(@$scheduled_events, $i, 1); # remove the (one-time) event
                $event->{scheduled} = 0;
            }
        }
        else {
            if ($time_of_next_event == 0 || $event->{time} < $time_of_next_event) {
                $time_of_next_event = $event->{time};
            }
        }
    }
    &App::sub_exit($time_of_next_event) if ($App::trace);
    return($time_of_next_event);
}

# NOTE: send_event() is similar to call(). I ought to resolve this.
sub send_event {
    &App::sub_entry if ($App::trace);
    my ($self, $event) = @_;
    my $method = $event->{method};
    my @args = $event->{args} ? @{$event->{args}} : ();
    my $service_type = $event->{service_type};
    if ($service_type) {
        my $name = $event->{name};
        my $service = $self->service($service_type, $name);
        $self->log("Send Event: $service_type($name).$method(@args)\n") if ($self->{verbose} >= 2);
        $service->$method(@args);
    }
    else {
        $self->log("Send Event: $method(@args)\n") if ($self->{verbose} >= 2);
        $self->$method(@args);
    }
    &App::sub_exit() if ($App::trace);
}

# NOTE: The baseline context doesn't implement asynchronous events.
#       Therefore, it simply sends the event, then sends the callback event.
#       See Context::Cluster for a context that spawns processes.
sub send_async_event {
    &App::sub_entry if ($App::trace);
    my ($self, $event, $callback_event) = @_;
    $self->send_event($event);
    if ($callback_event) {
        my $event_tag = "local-$$";
        if (! $callback_event->{args}) {
            $callback_event->{args} = [ $event_tag ];
        }
        $self->send_event($callback_event);
    }
    &App::sub_exit() if ($App::trace);
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
       
            $self->dbgprint("Context->shutdown(): $instance->_disconnect()")
                if ($App::DEBUG && $self->dbg(1));
     
            $instance->_disconnect();
            delete $repcache->{$repname};
        }
    }
}

1;

