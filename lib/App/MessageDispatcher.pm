
#############################################################################
## $Id: MessageDispatcher.pm,v 1.2 2002/10/15 21:58:49 spadkins Exp $
#############################################################################

package App::MessageDispatcher;

use App;
use App::Service;
@ISA = ( "App::Service" );

use strict;

=head1 NAME

App::MessageDispatcher - Interface for sending/receiving (possibly) async messages

=head1 SYNOPSIS

    use App;

    $context = App->context();
    $messaging = $context->service("MessageDispatcher");  # or ...
    $messaging = $context->messaging();

    ($status, $ticket) = $messaging->send(
        recipient => $recipient,
        message => $message
    );

    $message = $messaging->receive();

    $message = $messaging->receive(
        sender => $sender,
    );

    $message = $messaging->receive(
        ticket => $ticket,
    );

=head1 DESCRIPTION

A MessageDispatcher service is a means by which data can be sent asynchronously
(or synchronously) to a recipient and responses can be received.

Because the possibility exists for the messaging channel to be asynchronous,
code that uses a MessageDispatcher service must code for the most complicated case
(asynchronous).

=cut

#############################################################################
# CLASS GROUP
#############################################################################

=head1 Class Group: MessageDispatcher

The following classes might be a part of the MessageDispatcher Class Group.

=over

=item * Class: App::MessageDispatcher

=item * Class: App::MessageDispatcher::Mail

=item * Class: App::MessageDispatcher::SOAP

=item * Class: App::MessageDispatcher::Stem

=item * Class: App::MessageDispatcher::Spread

=item * Class: App::MessageDispatcher::Jabber

=item * Class: App::MessageDispatcher::PVM

=item * Class: App::MessageDispatcher::MPI

=back

=cut

#############################################################################
# CLASS
#############################################################################

=head1 Class: App::MessageDispatcher

A MessageDispatcher service is a means by which data can be sent synchronously
or asynchronously to a recipient and responses can be received.

 * Throws: App::Exception::MessageDispatcher
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
# send()
#############################################################################

=head2 send()

    * Signature: ($status, $ticket) = $messaging->send(%named);
    * Param:     recipient          string
    * Param:     message            binary
    * Return:    $status            integer
    * Return:    $ticket            string
    * Throws:    App::Exception::MessageDispatcher
    * Since:     0.01

    Sample Usage: 

    ($status, $ticket) = $messaging->send(
        recipient => "stephen.adkins\@officevision.com",
        message => "Hello.",
    );

=cut

sub send {
    my $self = shift;
    my %args = @_;
    my ($status, $ticket);
    ($status, $ticket);
}

#############################################################################
# receive()
#############################################################################

=head2 receive()

    * Signature: $message = $messaging->receive();
    * Signature: $message = $messaging->receive(%named);
    * Param:     sender          string
    * Param:     ticket          string
    * Return:    $message        binary
    * Throws:    App::Exception::MessageDispatcher
    * Since:     0.01

    Sample Usage: 

    # receive next available message
    $message = $messaging->receive();

    # receive next message from sender
    $message = $messaging->receive(
        sender => "stephen.adkins\@officevision.com",
    );

    # receive message associated with ticket
    $message = $messaging->receive(
        ticket => "XP305-3jks37sl.f299d",
    );

=cut

sub receive {
    my $self = shift;
    my %args = @_;
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

Returns 'MessageDispatcher'.

    * Signature: $service_type = App::MessageDispatcher->service_type();
    * Param:     void
    * Return:    $service_type  string
    * Since:     0.01

    $service_type = $mdisp->service_type();

=cut

sub service_type () { 'MessageDispatcher'; }

=head1 ACKNOWLEDGEMENTS

 * Author:  Stephen Adkins <stephen.adkins@officevision.com>
 * License: This is free software. It is licensed under the same terms as Perl itself.

=head1 SEE ALSO

L<C<App::Context>|App::Context>,
L<C<App::Service>|App::Service>

=cut

1;
