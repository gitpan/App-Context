
package App::Exceptions;

use strict;
use vars qw($VERSION);

$VERSION = sprintf '%2d.%02d', q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/;

my %e;

BEGIN {
    %e = (
        'App::Exception' => {
            description => 'An exception in a core App-Context class.',
        },

        'App::Exception::Context' => {
            description => 'An exception in the Context service.',
            isa => 'App::Exception',
        },

        'App::Exception::Conf' => {
            description => 'An exception in the Conf service.',
            isa => 'App::Exception',
        },

        'App::Exception::Serializer' => {
            description => 'An exception in the Serializer service.',
            isa => 'App::Exception',
        },

        'App::Exception::Security' => {
            description => 'An exception in the Security service.',
            isa => 'App::Exception',
        },

        'App::Exception::Session' => {
            description => 'An exception in the Session service.',
            isa => 'App::Exception',
        },

        'App::Exception::Procedure' => {
            description => 'An exception in the Procedure service.',
            isa => 'App::Exception',
        },

        'App::Exception::Messaging' => {
            description => 'An exception in the Messaging service.',
            isa => 'App::Exception',
        },

        'App::Exception::LogChannel' => {
            description => 'An exception in the LogChannel service.',
            isa => 'App::Exception',
        },

    );
}

use Exception::Class (%e);

if (1) {
    Exception::Class::Base->do_trace(1);
    foreach my $class (keys %e) {
        $class->do_trace(1);
    }
}

1;

=head1 NAME

App::Exceptions - Creates all exception classes used in App.

=head1 SYNOPSIS

  use App::Exception;

=head1 DESCRIPTION

Using this class creates all the exceptions classes used by App
(via the Exception::Class class). 
Stacktrace generation is turned on for all the exception classes.

See Exception::Class on CPAN for more information on
how this is done.

Note that there is really only one general
exception class defined for each App-Context Service. 
Within each Service, there may be a separate
exception hierarchy which is more fine-grained.  However, each
service is responsible to (1) handle these exceptions,
(2) handle these exceptions and rethrow
the general exception defined for the service, or
(3) derive all of the exceptions from the general exception.

=head1 EXCEPTION CLASSES

=over

=item * App::Exception

This is the base class for all exceptions generated within App (all
exceptions should return true for C<$@-E<gt>isa('App::Exception')>
except those that are generated via internal Perl errors).

=item * App::Exception::Context

Base class for all Context-related exceptions.

=item * App::Exception::Conf

Base class for all Conf-related exceptions.

=item * App::Exception::Serializer

Base class for all Serializer-related exceptions.

=item * App::Exception::Security

Base class for all Security-related exceptions.

=item * App::Exception::Session

Base class for all Session-related exceptions.

=item * App::Exception::Procedure

Base class for all Procedure-related exceptions.

=item * App::Exception::Messaging

Base class for all Messaging-related exceptions.

=item * App::Exception::LogChannel

Base class for all LogChannel-related exceptions.

=back

=head1 ACKNOWLEDGEMENTS

 * Author: Stephen Adkins <stephen.adkins@officevision.com>
 * Adapted from Dave Rolsky's Alzabo::Exceptions
 * License: This is free software. It is licensed under the same terms as Perl itself.

=cut

