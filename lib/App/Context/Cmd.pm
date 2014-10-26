
#############################################################################
## $Id: Cmd.pm,v 1.7 2004/02/27 14:23:55 spadkins Exp $
#############################################################################

package App::Context::Cmd;

use App;
use App::Context;
@ISA = ( "App::Context" );
use App::UserAgent;

use strict;

=head1 NAME

App::Context::Cmd - context in which we are currently running

=head1 SYNOPSIS

   # ... official way to get a Context object ...
   use App;
   $context = App->context();
   $config = $context->config();   # get the configuration
   $config->dispatch_events();     # dispatch events

   # ... alternative way (used internally) ...
   use App::Context::Cmd;
   $context = App::Context::Cmd->new();

=cut

#############################################################################
# DESCRIPTION
#############################################################################

=head1 DESCRIPTION

A Context class models the environment (aka "context)
in which the current process is running.
For the App::Context::Cmd class, this models any of the
web application runtime environments which employ the Cmd protocol
and produce HTML pages as output.  This includes CGI, mod_perl, FastCGI,
etc.  The difference between these environments is not in the Context
but in the implementation of the Request and Response objects.

=cut

#############################################################################
# PROTECTED METHODS
#############################################################################

=head1 Methods:

=cut

sub dispatch_events_begin {
    my ($self) = @_;

    my $options = $self->options();
    my $events = $self->{events};

    if ($#ARGV == -1 || $options->{"?"} || $options->{help}) {
        $self->_print_usage();
        exit(0);
    }

    my ($service, $name, $method, $args, $returntype, $contents);

    my $name_new = 0;

    $service = $options->{service} || "SessionObject";
    if ($#ARGV > -1 && $ARGV[0] =~ /^[A-Z]/) {
        $service = shift @ARGV;
    }

    $returntype = $options->{returntype} || "default";
    if ($#ARGV > -1 && $ARGV[$#ARGV] =~ /^:(.+)/) {
        $returntype = $1;
        pop(@ARGV);
    }
    $self->{returntype} = $returntype;

    $name = $options->{name} || "default";
    if ($#ARGV > -1) {
        $name = shift @ARGV;
    }

    $method = $options->{method} || "content";
    $method =~ /(.*)/;
    $method =  $1;

    if ($#ARGV > -1) {
        $method = shift @ARGV;
        $args = [];
        my ($arg);
        while ($#ARGV > -1) {
            $arg = shift(@ARGV);
            if ($arg =~ /^\[(.*)\]$/) {
                $contents = $1;
                if ($arg =~ /\|/) {
                    $arg = [ split(/ *\| */,$contents) ];
                }
                elsif ($arg =~ /:/) {
                    $arg = [ split(/ *: */,$contents) ];
                }
                elsif ($arg =~ /;/) {
                    $arg = [ split(/ *; */,$contents) ];
                }
                else {
                    $arg = [ split(/ *, */,$contents) ];
                }
            }
            elsif ($arg =~ /^\{(.*)\}$/) {
                $contents = $1;
                if ($arg =~ /\|/) {
                    $arg = { split(/ *[\|=>]+ */,$contents) };
                }
                elsif ($arg =~ /:/) {
                    $arg = { split(/ *[:=>]+ */,$contents) };
                }
                elsif ($arg =~ /;/) {
                    $arg = { split(/ *[;=>]+ */,$contents) };
                }
                else {
                    $arg = { split(/ *[,=>]+ */,$contents) };
                }
            }
            push(@$args, $arg);
        }
        push(@$events, [ $service, $name, $method, $args ]);
    }
}

sub _print_usage {
    print STDERR "--------------------------------------------------------------------\n";
    print STDERR "Usage: $0 [options] [<Service>] <name> [<method> [<args>]] [:returntype]\n";
    print STDERR "       --app=<tag>             default basename of options file (when file not specified)\n";
    print STDERR "       --prefix=<dir>          base directory of installed software (i.e. /usr/local)\n";
    print STDERR "       --debug_options         debug the option parsing process\n";
    print STDERR "       --perlinc=<dirlist>     directories to add to \@INC to find perl modules\n";
    print STDERR "       --import=<filelist>     additional config files to read\n";
    print STDERR "       --context_class=<class> class, default=App::Context::Cmd\n";
    print STDERR "       --debug=<level>         set debug level and scope, default=0\n";
    print STDERR "       --help or -?            print this message\n";
    print STDERR "--App::Context::Cmd-------------------------------------------------\n";
    print STDERR "       --service=<svc>         default curr service (default=SessionObject)\n";
    print STDERR "       --name=<name>           default curr name    (default=default)\n";
    print STDERR "       --method=<method>       default curr method  (default=content)\n";
    print STDERR "       --args=<args>           default curr args    (default=)\n";
    print STDERR "       --returntype=<type>     default curr return type (default=default)\n";
    print STDERR "       --session_class=<class> default=App::Session\n";
    print STDERR "       --conf_class=<class>    default=App::Conf::File\n";
    print STDERR "       --so_<var>=<value>      set SessionObject default value\n";
    print STDERR "--App::Conf::File---------------------------------------------------\n";
    print STDERR "       --debug_conf            debug the configuration process\n";
    print STDERR "       --conf_type=<type>      type of data (name of Serializer) in conf_file\n";
    print STDERR "       --conf_file=<file>      file name for full config file\n";
    print STDERR "       --conf_serializer_class=<class> class, default=App::Serializer\n";
    print STDERR "--Examples----------------------------------------------------------\n";
    print STDERR "       --debug=1                                      (global debug)\n";
    print STDERR "       --debug=1,App::Context                     (debug class only)\n";
    print STDERR "       --debug=3,App::Context,App::Session        (multiple classes)\n";
    print STDERR "       --debug=6,App::Repository::DBI.get_rows      (indiv. methods)\n";
    print STDERR "--------------------------------------------------------------------\n";
    exit(1);
}

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

Gets the currently logged in user id, or "guest" if it can't figure that out.

=cut

sub user {
    my $self = shift;
    return (getlogin || (getpwuid($<))[0] || "guest");
}

1;

