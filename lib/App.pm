
#############################################################################
## $Id: App.pm 3547 2006-02-25 16:32:17Z spadkins $
#############################################################################

package App;

use strict;

# eliminate warnings about uninitialized values
$SIG{__WARN__} = sub { warn @_ unless $_[0] =~ /Use of uninitialized value/};

use Exception::Class;   # enable Exception inheritance
use App::Exceptions;

=head1 NAME

App - Backplane for core App services

=head1 SYNOPSIS

    use App;

    my ($context, $conf, $object);
    $context = App->context();  # singleton per process
    $conf    = App->conf();   # returns a hashref to conf
    $context = App->new();
    $object  = App->new($class);
    $object  = App->new($class, $method);
    $object  = App->new($class, $method, @args);

=head1 DESCRIPTION

The App module is the module from which core services are
called.

=cut

#############################################################################
# DISTRIBUTION
#############################################################################

=head1 Distribution: App-Context

The App-Context distribution is the core set of modules implementing
the core of an enterprise application development framework.

    http://www.officevision.com/pub/App-Context

    * Version: 0.01

It provides the following services.

    * Application Configuration (App::Conf::*)
    * Session Management (App::Session::*)
    * Remote Procedure Call (App::Procedure::*)
    * Session Objects and Remote Method Invocation (App::SessionObject::*)
    * Multiprocess-safe Name-Value Storage (App::SharedDatastore::*)
    * Shared Resource Pooling and Locking (App::SharedResourceSet::*)

One of App-Context's extended services (App::Repository::*)
adds distributed transaction capabilities and access to data
from a variety of sources through a uniform interface.

In the same distribution (App-Repository), is a base class,
App::RepositoryObject, which serves as the base class for
implementing persistent business objects.

    http://www.officevision.com/pub/App-Repository

Another of App-Context's extended services (App::Widget::*)
adds simple and complex active user interface widgets.
These widgets can be used to supplement an existing application's
user interface technology (template systems, hard-coded HTML, etc.)
or the Widget system can be used as the central user interface paradigm.

    http://www.officevision.com/pub/App-Widget

App-Context and its extended service distributions were
inspired by work on the Perl 5 Enterprise Environment project,
and its goal is to satisfy the all of the requirements embodied in
the Attributes of an Enterprise System.

See the following web pages for more information about the P5EE project.

    http://p5ee.perl.org/
    http://www.officevision.com/pub/p5ee/

=head2 Distribution Requirements

The following are enumerated requirements for the App-Context distribution.
It forms a high-level feature list. 
The requirements which have been satisfied
(or features implemented) have an "x" by them, whereas the requirements
which have yet-to-be satisfied have an "o" by them.

    o an Enterprise Software Architecture, supporting all the Attributes
        http://www.officevision.com/pub/p5ee/definitions.html
    o a Software Architecture supporting many Platforms
        http://www.officevision.com/pub/p5ee/platform.html
    o a pluggable interface/implementation service architecture
    o support developers who wish to use portions of the App-Context
        framework without giving up their other styles of programming
        (and support gradual migration)

=head2 Distribution Design

The distribution is designed in such a way that most of the functionality
is actually provided by modules outside the App namespace.

The goal of the App-Context framework
is to bring together many technologies to make a
unified whole.  In essence, it is collecting and unifying the good work
of a multitude of excellent projects which have already been developed.
This results in a Pluggable Service design which allows just about
everything in App-Context to be customized.  These Class Groups are described
in detail below.

Where a variety of excellent, overlapping or redundant, low-level modules
exist on CPAN (i.e. L<date and time modules|App::datetime>),
a document is
written to explain the pros and cons of each.

Where uniquely excellent modules exist on CPAN, they are named outright
as the standard for the App-Context framework. 
They are identified as dependencies
in the App-Context CPAN Bundle file.

=head2 Class Groups

The major Class Groups in the App-Context distribution fall into three categories:
Core, Core Services, and Services.

=over

=item * Class Group: L<C<Core>|"Class Group: Core">

=item * Class Group: L<C<Context>|App::Context>
      - encapsulates the runtime environment and the event loop

=item * Class Group: L<C<Conf>|App::Conf>
      - retrieve and access configuration information

=item * Class Group: L<C<Session>|App::Session>
      - represents the state associated with a sequence of multiple events

=item * Class Group: L<C<Serializer>|App::Serializer>
      - transforms a perl struct to a scalar and back

=item * Class Group: L<C<Procedure>|App::Procedure>
      - a (potentially remote) procedure which may be executed

=item * Class Group: L<C<Messaging>|App::Messaging>
      - a message queue with configurable quality of service

=item * Class Group: L<C<Security>|App::Security>
      - provides authentication and authorization

=item * Class Group: L<C<LogChannel>|App::LogChannel>
      - a logging channel through which messages may be logged

=item * Class Group: L<C<SharedDatastore>|App::SharedDatastore>
      - a data storage area which is shared between processes

=item * Class Group: L<C<SharedResourceSet>|App::SharedResourceSet>
      - a set of shared resources which may be locked for exclusive access

=back

=cut

#############################################################################
# CLASS GROUP
#############################################################################

=head1 Class Group: Core

The Core Class Group contains the following classes.

=over

=item * Class: L<C<App>|"Class: App">

=item * Class: L<C<App::Reference>|App::Exceptions>

=item * Class: L<C<App::Reference>|App::Reference>

=item * Class: L<C<App::Service>|App::Service>

=item * Document: L<C<Perlstyle, Perl Style Guide>|App::perlstyle>

=item * Document: L<C<Podstyle, POD Documentation Guide>|App::podstyle>

=item * Document: L<C<Datetime, Dates and Times in App-Context>|App::datetime>

=back

=cut

#############################################################################
# CLASS
#############################################################################

=head1 Class: App

App is the main class through which all of the features
of the Perl 5 Enterprise Environment may be accessed.

 * Throws: Exception::Class::Base
 * Throws: App::Exception
 * Throws: App::Exception::Conf
 * Throws: App::Exception::Context
 * Since:  0.01

=head2 Class Design

The class is entirely made up of static (class) methods.
There are no constructors for objects of this class itself.
Rather, all of the constructors in this package are really
factory-style constructors that return objects of different
classes.
In particular, the new() method is really a synonym for context(),
which returns a Context object.

=head2 Class Capabilities

This class supports the following capabilities.

=over

=item * Capability: Service Factory

This package allows you to construct objects (services) that
you do not know
the classes for at development time.  These classes are specified
through the configuration and are produced using this package as
a class factory.

=back

=cut

#############################################################################
# ATTRIBUTES/CONSTANTS/CLASS VARIABLES/GLOBAL VARIABLES
#############################################################################

=head1 Attributes, Constants, Global Variables, Class Variables

=head2 Global Variables

 * Global Variable: %App::scope              scope for debug or tracing output
 * Global Variable: $App::scope_exclusive    flag saying that the scope is exclusive (a list of things *not* to debug/trace)
 * Global Variable: %App::trace              trace level
 * Global Variable: $App::DEBUG              debug level
 * Global Variable: $App::DEBUG_FILE         file for debug output

=cut

if (!defined $App::DEBUG) {
    %App::scope = ();
    $App::scope_exclusive = 0;
    $App::trace = 0;
    $App::DEBUG = 0;
    $App::DEBUG_FILE = "";
}

#################################################################
# DEBUGGING
#################################################################

# Supports the following command-line usage:
#    --debug=1                                     (global debug)
#    --debug=9                                     (detail debug)
#    --scope=App::Context                      (debug class only)
#    --scope=!App::Context             (debug all but this class)
#    --scope=App::Context,App::Session         (multiple classes)
#    --scope=App::Repository::DBI.select_rows    (indiv. methods)
#    --trace=App::Context                      (trace class only)
#    --trace=!App::Context             (trace all but this class)
#    --trace=App::Context,App::Session         (multiple classes)
#    --trace=App::Repository::DBI.select_rows    (indiv. methods)
{
    my $scope = $App::options{scope} || "";

    my $trace = $App::options{trace};
    if ($trace) {
        if ($trace =~ s/^([0-9]+),?//) {
            $App::trace = $1;
        }
        else {
            $App::trace = 9;
        }
    }
    if ($trace) {
        $scope .= "," if ($scope);
        $scope .= $trace;
    }
    $App::trace_width = (defined $App::options{trace_width}) ? $App::options{trace_width} : 1024;
    $App::trace_justify = (defined $App::options{trace_justify}) ? $App::options{trace_justify} : 0;

    my $debug = $App::options{debug};
    if ($debug) {
        if ($debug =~ s/^([0-9]+),?//) {
            $App::DEBUG = $1;
        }
        else {
            $App::DEBUG = 9;
        }
    }
    if ($debug) {
        $scope .= "," if ($scope);
        $scope .= $debug;
    }

    if ($scope =~ s/^!//) {
        $App::scope_exclusive = 1;
    }

    if (defined $scope && $scope ne "") {
        foreach my $pkg (split(/,/,$scope)) {
            $App::scope{$pkg} = 1;
        }
    }

    my $debug_file = $App::options{debug_file};
    if ($debug_file) {
        if ($debug_file !~ /^[>|]/) {
            $debug_file = ">> $debug_file";
        }
        open(App::DEBUG_FILE, $debug_file);
    }
}

#############################################################################
# SUPPORT FOR ASPECT-ORIENTED-PROGRAMMING (AOP)
#############################################################################

=head1 Code Inclusion and Instrumentation

=cut

#############################################################################
# use()
#############################################################################

=head2 use()

    * Signature: App->use($class);
    * Param:  $class      string  [in]
    * Return: void
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    App->use("App::Widget::Entity");

The use() method loads additional perl code and enables aspect-oriented
programming (AOP) features if they are appropriate.  If these did not
need to be turned on or off, it would be easier to simply use the
following.

  eval "use $class;"

The first AOP
feature planned is the printing of arguments on entry to a method and
the printing of arguments and return values on exit of a a method.

This is useful
for debugging and the generation of object-message traces to validate
or document the flow of messages through the system.

Detailed Conditions:

  * use(001) class does not exist: throw a App::Exception
  * use(002) class never used before: should succeed
  * use(003) class used before: should succeed
  * use(004) can use class after: should succeed

=cut

my (%used);

sub use ($) {
    &App::sub_entry if ($App::trace);
    my ($self, $class) = @_;
    if (! defined $used{$class}) {
        # if we try to use() it again, we won't get an exception
        $used{$class} = 1;
        if ($class =~ /^([A-Za-z0-9_:]+)$/) {
            eval "use $1;";
            if ($@) {
                App::Exception->throw(
                    error => "class $class failed to load: $@\n",
                );
            }
        }
        else {
            App::Exception->throw(
                error => "Tried to load class [$class] with illegal characters\n",
            );
        }
    }
    &App::sub_exit() if ($App::trace);
}

#############################################################################
# printargs()
#############################################################################

=head2 printargs()

    * Signature: App->printargs($depth, $skipatend, @args);
    * Param:     $depth       integer  [in]
    * Param:     $skipatend   integer  [in]
    * Param:     @args        any      [in]
    * Return:    void
    * Throws:    none
    * Since:     0.01

=cut

sub printargs {
    my $depth = shift;
    my $skipatend = shift;
    my ($narg);
    for ($narg = 0; $narg <= $#_ - $skipatend; $narg++) {
        print "," if ($narg);
        if (ref($_[$narg]) eq "") {
            print $_[$narg];
        }
        elsif (ref($_[$narg]) eq "ARRAY") {
            print "[";
            if ($depth <= 1) {
                print join(",", @{$_[$narg]});
            }
            else {
                &printdepth($depth-1, 0, @{$_[$narg]});
            }
            print "]";
        }
        elsif (ref($_[$narg]) eq "HASH") {
            print "{";
            if ($depth <= 1) {
                print join(",", %{$_[$narg]});
            }
            else {
                &printdepth($depth-1, 0, %{$_[$narg]});
            }
            print "}";
        }
        else {
            print $_[$narg];
        }
    }
}

#############################################################################
# CONSTRUCTOR METHODS
#############################################################################

=head1 Constructor Methods:

=cut

#############################################################################
# new()
#############################################################################

=head2 new()

The App->new() method is not a constructor for
an App class.  Rather, it is a Factory-style constructor, returning
an object of the class given as the first parameter.

If no parameters are given,
it is simply a synonym for "App->context()".

    * Signature: $context = App->new()
    * Signature: $object = App->new($class)
    * Signature: $object = App->new($class,$method)
    * Signature: $object = App->new($class,$method,@args)
    * Param:  $class       class  [in]
    * Param:  $method      string [in]
    * Return: $context     App::Context
    * Return: $object      ref
    * Throws: Exception::Class::Base
    * Since:  0.01

    Sample Usage: 

    $context = App->new();
    $dbh = App->new("DBI", "new", "dbi:mysql:db", "dbuser", "xyzzy");
    $cgi = App->new("CGI", "new");

=cut

sub new {
    &App::sub_entry if ($App::trace);
    my $self = shift;
    if ($#_ == -1) {
        my $context = $self->context();
        &App::sub_exit($context) if ($App::trace);
        return($context);
    }
    my $class = shift;
    if ($class =~ /^([A-Za-z0-9:_]+)$/) {
        $class = $1;  # untaint the $class
        if (! $used{$class}) {
            $self->use($class);
        }
        my $method = ($#_ > -1) ? shift : "new";
        if (wantarray) {
            my @values = $class->$method(@_);
            &App::sub_exit(@values) if ($App::trace);
            return(@values);
        }
        else {
            my $value = $class->$method(@_);
            &App::sub_exit($value) if ($App::trace);
            return($value);
        }
    }
    print STDERR "Illegal Class Name: [$class]\n";
    &App::sub_exit(undef) if ($App::trace);
    return undef;
}

#############################################################################
# context()
#############################################################################

=head2 context()

    * Signature: $context = App->context();      # most common, used in "app"
    * Signature: $context = App->context(%named);                 # also used
    * Signature: $context = App->context($named, %named);         # variation
    * Signature: $context = App->context($name, %named);               # rare
    * Signature: $context = App->context($named, $name, %named);       # rare
    * Param:     context_class   class  [in]
    * Param:     config_file     string [in]
    * Param:     prefix          string [in]
    * Return:    $context        App::Context
    * Throws:    App::Exception::Context
    * Since:     0.01

    Sample Usage: 

    $context = App->context();
    $context = App->context(
        context_class => "App::Context::HTTP",
        config_file => "app.xml",
    );

This static (class) method returns the $context object
of the context in which you are running.
It tries to use some intelligence in determining which
context is the right one to instantiate, although you
can override it explicitly.

It implements a "Factory" design pattern.  Instead of using the
constructor of a class itself to get an instance of that
class, the context() method of App is used.  The former
technique would require us to know at development time
which class was to be instantiated.  Using the factory
style constructor, the developer need not ever know what physical class
is implementing the "Context" interface.  Rather, it is
configured at deployment-time, and the proper physical class
is instantiated at run-time.

The new() method of the configured Context class is called to
instantiate the proper Context object.  The $named args are
combined with the %named args and passed as a single hash
reference to the new() method.

Environment variables:

    PREFIX - set the $conf->{prefix} variable if not set to set app root dir
    APP_CONTEXT_CLASS - set the Perl module to instantiate for the Context
    GATEWAY_INTERFACE - assume mod_perl, use App::Context::ModPerl
    HTTP_USER_AGENT - assume CGI, use App::Context::HTTP
      (otherwise, use App::Context::Cmd, assuming it is from command line)

=cut

my (%context);  # usually a singleton per process (under "default" name)
                # multiple named contexts are allowed for debugging purposes

sub context {
    &App::sub_entry if ($App::trace);
    my $self = shift;

    my ($name, $options, $i);
    if ($#_ == -1) {               # if no options supplied (the normal case)
        $options = (%App::options) ? \%App::options : {};      # options hash
        $name = "default";                 # name of the singleton is default
    }
    else {                                     # named args were supplied ...
        if (ref($_[0]) eq "HASH") {                 # ... as a hash reference
            $options = shift;                # note that a copy is *not* made
            for ($i = 0; $i < $#_; $i++) {            # copy other named args
                $options->{$_[$i]} = $_[$i+1];        # into the options hash
            }
        }
        else {                                  # ... as a list of var/values
            $name = shift if ($#_ % 2 == 0);    # if odd #, first is the name
            $options = ($#_ > -1) ? { @_ } : {};    # the rest are named args
        }
        $name = $options->{name} if (!$name); # if not given, look in options
        $name = "default" if (!$name);                # use "default" as name
    }

    if (!defined $context{$name}) {
    
        if (! $options->{context_class}) {
            if (defined $ENV{APP_CONTEXT_CLASS}) {        # env variable set?
                $options->{context_class} = $ENV{APP_CONTEXT_CLASS};
            }
            else {   # try autodetection ...
                my $gateway = $ENV{GATEWAY_INTERFACE};
                if (defined $gateway && $gateway =~ /CGI-Perl/) { # mod_perl?
                    $options->{context_class} = "App::Context::ModPerl";
                }
                elsif ($ENV{HTTP_USER_AGENT}) {  # running as CGI script?
                    $options->{context_class} = "App::Context::HTTP";
                }
                else {   # assume it is from the command line
                    $options->{context_class} = "App::Context::Cmd";
                }
            }
        }
        if (!$options->{prefix}) {                # if this isn't already set
            if ($ENV{PREFIX}) {             # but it's set in the environment
                $options->{prefix} = $ENV{PREFIX};              # then set it
            }
        }

        # instantiate Context and cache it (it's reference) for future use
        $context{$name} = $self->new($options->{context_class}, "new", $options);
    }

    &App::sub_exit($context{$name}) if ($App::trace);
    return($context{$name});
}

sub shutdown {
    &App::sub_entry if ($App::trace);
    my ($self, $name) = @_;
    $name = "default" if (!defined $name);
    $context{$name}->shutdown() if (defined $context{$name});
    delete $context{$name};
    &App::sub_exit() if ($App::trace);
}

#############################################################################
# conf()
#############################################################################

=head2 conf()

    * Signature: $conf = App->conf(%named);
    * Param:     conf_class  class  [in]
    * Param:     config_file string [in]
    * Return:    $conf      App::Conf
    * Throws:    App::Exception::Conf
    * Since:     0.01

This gets the Conf object from the Context.

If args are passed in, they are only effective in affecting the Context
if the Context has not been instantiated before.

After the Context is instantiated by either the App->context() call or the
App->conf() call, then subsequent calls to either method may or may not
include arguments.  It will not have any further effect because the
Context object instantiated earlier will be used.

=cut

sub conf {
    &App::sub_entry if ($App::trace);
    my $self = shift;
    my $retval = $self->context(@_)->conf();
    &App::sub_exit($retval) if ($App::trace);
    $retval;
}

#############################################################################
# info()
#############################################################################

=head2 info()

    * Signature: $ident = App->info();
    * Param:     void
    * Return:    $ident     string
    * Throws:    App::Exception
    * Since:     0.01

Gets version info about the framework.

=cut

sub info {
    &App::sub_entry if ($App::trace);
    my $self = shift;
    my $retval = "App-Context ($App::VERSION)";
    &App::sub_exit($retval) if ($App::trace);
    return($retval);
}

#############################################################################
# Aspect-oriented programming support
#############################################################################
# NOTE: This can be done much more elegantly at the Perl language level,
# but it requires version-specific code.  I created these subroutines so that
# any method that is instrumented with them will enable aspect-oriented
# programming in Perl versions from 5.5.3 to the present.
#############################################################################

my $calldepth = 0;

#############################################################################
# sub_entry()
#############################################################################

=head2 sub_entry()

    * Signature: &App::sub_entry;
    * Signature: &App::sub_entry(@args);
    * Param:     @args        any
    * Return:    void
    * Throws:    none
    * Since:     0.01

This is called at the beginning of a subroutine or method (even before $self
may be shifted off).

=cut

sub sub_entry {
    if ($App::trace) {
        my ($stacklevel, $calling_package, $file, $line, $subroutine, $hasargs, $wantarray, $text);
        $stacklevel = 1;
        ($calling_package, $file, $line, $subroutine, $hasargs, $wantarray) = caller($stacklevel);
        while (defined $subroutine && $subroutine eq "(eval)") {
            $stacklevel++;
            ($calling_package, $file, $line, $subroutine, $hasargs, $wantarray) = caller($stacklevel);
        }
        my ($name, $obj, $class, $package, $sub, $method, $firstarg, $trailer);

        # split subroutine into its "package" and the "sub" within the package
        if ($subroutine =~ /^(.*)::([^:]+)$/) {
            $package = $1;
            $sub = $2;
        }

        # check if it might be a method call rather than a normal subroutine call
        if ($#_ >= 0) {
            $class = ref($_[0]);
            if ($class) {
                $obj = $_[0];
                $method = $sub if ($class ne "ARRAY" && $class ne "HASH");
            }
            else {
                $class = $_[0];
                if ($class =~ /^[A-Z][A-Za-z0-9_:]*$/ && $class->isa($package)) {
                    $method = $sub;  # the sub is a method call on the class
                }
                else {
                    $class = "";     # it wasn't really a class/method
                }
            }
        }

        if (%App::scope) {
            if ($App::scope_exclusive) {
                return if ($App::scope{$package} || $App::scope{"$package.$sub"});
            }
            else {
                return if (!$App::scope{$package} && !$App::scope{"$package.$sub"});
            }
        }

        if ($method) {
            if (ref($obj)) {  # dynamic method, called on an object
                if ($obj->isa("App::Service")) {
                    $text = ("| " x $calldepth) . "+-" . $obj->{name} . "->${method}(";
                }
                else {
                    $text = ("| " x $calldepth) . "+-" . $obj . "->${method}(";
                }
                $trailer = " [$package]";
            }
            else {   # static method, called on a class
                $text = ("| " x $calldepth) . "+-" . "${class}->${method}(";
                $trailer = ($class eq $package) ? "" : " [$package]";
            }
            $firstarg = 1;
        }
        else {
            $text = ("| " x $calldepth) . "+-" . $subroutine . "(";
            $firstarg = 0;
            $trailer = "";
        }
        my ($narg);
        for ($narg = $firstarg; $narg <= $#_; $narg++) {
            $text .= "," if ($narg > $firstarg);
            if (!defined $_[$narg]) {
                $text .= "undef";
            }
            elsif (ref($_[$narg]) eq "") {
                $text .= $_[$narg];
            }
            elsif (ref($_[$narg]) eq "ARRAY") {
                $text .= ("[" . join(",", map { defined $_ ? $_ : "undef" } @{$_[$narg]}) . "]");
            }
            elsif (ref($_[$narg]) eq "HASH") {
                $text .= ("{" . join(",", map { defined $_ ? $_ : "undef" } %{$_[$narg]}) . "}");
            }
            else {
                $text .= $_[$narg];
            }
        }
        #$trailer .= " [package=$package sub=$sub subroutine=$subroutine class=$class method=$method]";
        $text .= ")";
        my $trailer_len = length($trailer);
        $text =~ s/\n/\\n/g;
        my $text_len = length($text);
        if ($App::trace_width) {
            if ($text_len + $trailer_len > $App::trace_width) {
                my $len = $App::trace_width - $trailer_len;
                $len = 1 if ($len < 1);
                print substr($text, 0, $len), $trailer, "\n";
            }
            elsif ($App::trace_justify) {
                my $len = $App::trace_width - $trailer_len - $text_len;
                $len = 0 if ($len < 0);  # should never happen
                print $text, ("." x $len), $trailer, "\n";
            }
            else {
                print $text, $trailer, "\n";
            }
        }
        else {
            print $text, $trailer, "\n";
        }
        $calldepth++;
    }
}

#############################################################################
# sub_exit()
#############################################################################

=head2 sub_exit()

    * Signature: &App::sub_exit(@return);
    * Param:     @return      any
    * Return:    void
    * Throws:    none
    * Since:     0.01

This subroutine is called just before you return from a subroutine or method.
=cut

sub sub_exit {
    if ($App::trace) {
        my ($stacklevel, $calling_package, $file, $line, $subroutine, $hasargs, $wantarray, $text);
        $stacklevel = 1;
        ($calling_package, $file, $line, $subroutine, $hasargs, $wantarray) = caller($stacklevel);
        while (defined $subroutine && $subroutine eq "(eval)") {
            $stacklevel++;
            ($calling_package, $file, $line, $subroutine, $hasargs, $wantarray) = caller($stacklevel);
        }

        my ($package, $sub);
        # split subroutine into its "package" and the "sub" within the package
        if ($subroutine =~ /^(.*)::([^:]+)$/) {
            $package = $1;
            $sub = $2;
        }

        return if (%App::scope && !$App::scope{$package} && !$App::scope{"$package.$sub"});

        $calldepth--;
        $text = ("| " x $calldepth) . "+-> $sub()";
        my ($narg, $arg);
        for ($narg = 0; $narg <= $#_; $narg++) {
            $text .= $narg ? "," : " : ";
            $arg = $_[$narg];
            if (! defined $arg) {
                $text .= "undef";
            }
            elsif (ref($arg) eq "") {
                $text .= $arg;
            }
            elsif (ref($arg) eq "ARRAY") {
                $text .= ("[" . join(",", map { defined $_ ? $_ : "undef" } @$arg) . "]");
            }
            elsif (ref($arg) eq "HASH") {
                $text .= ("{" . join(",", map { defined $_ ? $_ : "undef" } %$arg) . "}");
            }
            else {
                $text .= defined $arg ? $arg : "undef";
            }
        }
        $text =~ s/\n/\\n/g;
        if ($App::trace_width && length($text) > $App::trace_width) {
            print substr($text, 0, $App::trace_width), "\n";
        }
        else {
            print $text, "\n";
        }
    }
    return(@_);
}

#############################################################################
# in_debug_scope()
#############################################################################

=head2 in_debug_scope()

    * Signature: &App::in_debug_scope
    * Signature: App->in_debug_scope
    * Param:     <no arg list supplied>
    * Return:    void
    * Throws:    none
    * Since:     0.01

This is called within a subroutine or method in order to see if debug output
should be produced.

  if ($App::debug && &App::in_debug_scope) {
      print "This is debug output\n";
  }

Note: The App::in_debug_scope subroutine also checks $App::debug, but checking
it in your code allows you to skip the subroutine call if you are not debugging.

  if (&App::in_debug_scope) {
      print "This is debug output\n";
  }

=cut

sub in_debug_scope {
    if ($App::debug) {
        my ($stacklevel, $calling_package, $file, $line, $subroutine, $hasargs, $wantarray, $text);
        $stacklevel = 1;
        ($calling_package, $file, $line, $subroutine, $hasargs, $wantarray) = caller($stacklevel);
        while (defined $subroutine && $subroutine eq "(eval)") {
            $stacklevel++;
            ($calling_package, $file, $line, $subroutine, $hasargs, $wantarray) = caller($stacklevel);
        }
        my ($package, $sub);

        # split subroutine into its "package" and the "sub" within the package
        if ($subroutine =~ /^(.*)::([^:]+)$/) {
            $package = $1;
            $sub = $2;
        }

        if (%App::scope) {
            if ($App::scope_exclusive) {
                return(undef) if ($App::scope{$package} || $App::scope{"$package.$sub"});
            }
            else {
                return(undef) if (!$App::scope{$package} && !$App::scope{"$package.$sub"});
            }
        }
        return(1);
    }
    return(undef);
}

#############################################################################
# debug_indent()
#############################################################################

=head2 debug_indent()

    * Signature: &App::debug_indent()
    * Signature: App->debug_indent()
    * Param:     void
    * Return:    $indent_str     string
    * Throws:    none
    * Since:     0.01

This subroutine returns the $indent_str string which should be printed
before all debug lines if you wish to line the debug output up with the
nested/indented trace output.

=cut

sub debug_indent {
    my $text = ("| " x $calldepth) . "  * ";
    return($text);
}

=head1 ACKNOWLEDGEMENTS

 * Author:  Stephen Adkins <stephen.adkins@officevision.com>
 * License: This is free software. It is licensed under the same terms as Perl itself.

=head1 SEE ALSO

=cut

1;

