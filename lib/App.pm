
#############################################################################
## $Id: App.pm,v 1.2 2002/09/18 02:54:10 spadkins Exp $
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

 * Global Variable: $App::DEBUG      integer

=cut

$App::DEBUG = 0 if (!defined $App::DEBUG);

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
my (%class_aop_enabled, %class_aop_instrumented);
my ($aop_entry, $aop_exit, @advice);

sub use ($) {
    my ($self, $class) = @_;
    return if (defined $used{$class});
    eval "use $class;";
    if ($@) {
        App::Exception->throw(
            error => "class $class failed to load: $@\n",
        );
    }
    $used{$class} = 1;
    @advice = ();
    #App->instrument_aop();
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
a App class.  However, it is a constructor, returning
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
    $dbh = App->new("DBI", "new", "dbi:mysql:db", "dbuser", "dbpasswd2");
    $cgi = App->new("CGI", "new");

=cut

sub new {
    my $self = shift;
    return $self->context() if ($#_ == -1);
    my $class = shift;
    if ($class =~ /^([A-Za-z0-9:_]+)$/) {
        $class = $1;  # untaint the $class
        if (! $used{$class}) {
            $self->use($class);
        }
        my $method = ($#_ > -1) ? shift : "new";
        return $class->$method(@_);
    }
    print STDERR "Illegal Class Name: [$class]\n";
    return undef;
}

#############################################################################
# context()
#############################################################################

=head2 context()

    * Signature: $context = App->context()
    * Param:     contextClass class  [in]
    * Param:     confFile     string [in]
    * Return:    $context     App::Context
    * Throws:    App::Exception::Context
    * Since:     0.01

    Sample Usage: 

    $context = App->context();
    $context = App->context(
        contextClass => "App::Context::HTTP",
        confFile => "app.xml",
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

=cut

my (%context);  # usually a singleton per process (under "default" name)
                # multiple named contexts are allowed for debugging purposes

sub context {
    my $self = shift;

    my ($name, $args, $i);
    if ($#_ == -1) {
        $args = {};
        $name = "default";
    }
    else {
        if (ref($_[0]) eq "HASH") {
            $args = shift;
            $name = shift if ($#_ % 2 == 0);
            for ($i = 0; $i < $#_; $i++) {
                $args->{$_[$i]} = $_[$i+1];
            }
        }
        else {
            $name = shift if ($#_ % 2 == 0);
            $args = ($#_ > -1) ? { @_ } : {};
        }
        $name = $args->{name} if (!$name);
        $name = "default" if (!$name);
    }
    return ($context{$name}) if (defined $context{$name});
    
    if (! $args->{contextClass}) {
        if (defined $ENV{APP_CONTEXT_CLASS}) {     # env variable set?
            $args->{contextClass} = $ENV{APP_CONTEXT_CLASS};
        }
        else {   # try autodetection ...
            my $gateway = $ENV{GATEWAY_INTERFACE};
            if (defined $gateway && $gateway =~ /CGI-Perl/) {  # mod_perl?
                $args->{contextClass} = "App::Context::HTTP";
            }
            elsif ($ENV{HTTP_USER_AGENT}) {  # running as CGI script?
                $args->{contextClass} = "App::Context::HTTP";
            }
            # let's be real... these next two are not critical right now
            #elsif ($ENV{DISPLAY}) { # running with an X DISPLAY var set?
            #    $args->{contextClass} = "App::Context::Gtk";
            #}
            #elsif ($ENV{TERM}) { # running with a TERM var for Curses?
            #    $args->{contextClass} = "App::Context::Curses";
            #}
            else {   # fall back to CGI, because it works OK in command mode
                $args->{contextClass} = "App::Context::HTTP";
            }
        }
    }

    $context{$name} = $self->new($args->{contextClass}, "new", $args);
    return $context{$name};
}

#############################################################################
# conf()
#############################################################################

=head2 conf()

    * Signature: $conf = App->conf(%named);
    * Param:     confClass  class  [in]
    * Param:     confFile   string [in]
    * Return:    $conf      App::Conf
    * Throws:    App::Exception::Conf
    * Since:     0.01

=cut

sub conf {
    my $self = shift;

    my ($name, $args, $i);
    if ($#_ == -1) {
        $args = {};
        $name = "default";
    }
    else {
        if (ref($_[0]) eq "HASH") {
            $args = shift;
            $name = shift if ($#_ % 2 == 0);
            for ($i = 0; $i < $#_; $i += 2) {
                $args->{$_[$i]} = $_[$i+1];
            }
        }
        else {
            $name = shift if ($#_ % 2 == 0);
            $args = ($#_ > -1) ? { @_ } : {};
        }
        $name = $args->{name} if (!$name);
        $name = "default" if (!$name);
    }

    $self->context($args)->conf();
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

=cut

sub info {
    my $self = shift;
    "App-Context ($App::VERSION)";
}

=head1 ACKNOWLEDGEMENTS

 * Author:  Stephen Adkins <stephen.adkins@officevision.com>
 * License: This is free software. It is licensed under the same terms as Perl itself.

=head1 SEE ALSO

=cut

1;

