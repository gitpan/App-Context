
#############################################################################
## $Id: Authorization.pm 3227 2002-10-15 21:58:49Z spadkins $
#############################################################################

package App::LogChannel;

use App;
use App::Service;
@ISA = ( "App::Service" );

use strict;

=head1 NAME

App::LogChannel - Interface for logging

=head1 SYNOPSIS

    use App;

    $context = App->context();
    $logchannel = $context->service("LogChannel");  # or ...
    $logchannel = $context->logchannel();

=head1 DESCRIPTION

A LogChannel service is a means by which messages are logged through a
logging system.  This perhaps ends up in a file, or perhaps it
ends up on someone's operator console screen somewhere.

=cut

#############################################################################
# CLASS GROUP
#############################################################################

=head1 Class Group: LogChannel

The following classes might be a part of the LogChannel Class Group.

=over

=item * Class: App::LogChannel

=item * Class: App::LogChannel::LogDispatch

=item * Class: App::LogChannel::NetDaemon

=back

=cut

#############################################################################
# CLASS
#############################################################################

=head1 Class: App::LogChannel

A LogChannel service ...

 * Throws: App::Exception::LogChannel
 * Since:  0.01

=head2 Class Design

...

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

The constructor is inherited from
L<C<App::Service>|App::Service/"new()">.

=cut

#############################################################################
# PUBLIC METHODS
#############################################################################

=head1 Public Methods:

=cut

#############################################################################
# log()
#############################################################################

=head2 log()

    * Signature: $logchannel->log(@text);
    * Param:     @text              array[string]
    * Return:    void
    * Throws:    App::Exception::LogChannel
    * Since:     0.01

    Sample Usage: 

    $context = App->context();
    $logchannel = $context->service("LogChannel");  # or ...
    $logchannel->log("Error occurred");

=cut

sub log {
    my ($self, @text) = @_;
    print STDERR @text, "\n";
}

#############################################################################
# PROTECTED METHODS
#############################################################################

=head1 Protected Methods:

=cut

#############################################################################
# Method: service_type()
#############################################################################

=head2 service_type()

Returns 'LogChannel';

    * Signature: $service_type = App::LogChannel->service_type();
    * Param:     void
    * Return:    $service_type  string
    * Since:     0.01

    $service_type = $authz->service_type();

=cut

sub service_type () { 'Authorization'; }

=head1 ACKNOWLEDGEMENTS

 * Author:  Stephen Adkins <stephen.adkins@officevision.com>
 * License: This is free software. It is licensed under the same terms as Perl itself.

=head1 SEE ALSO

L<C<App::Context>|App::Context>,
L<C<App::Service>|App::Service>

=cut

1;

