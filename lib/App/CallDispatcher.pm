
#############################################################################
## $Id: CallDispatcher.pm,v 1.1 2002/10/07 21:55:58 spadkins Exp $
#############################################################################

package App::CallDispatcher;

use App;
use App::Service;
@ISA = ( "App::Service" );

use strict;

=head1 NAME

App::CallDispatcher - synchronous (potentially remote) procedure invocation

=head1 SYNOPSIS

    use App;

    $context = App->context();
    $procedure = $context->service("CallDispatcher");  # or ...
    $procedure = $context->procedure();

    $procedure->execute($request, $response);
    $response = $procedure->execute($request);
    $response = $procedure->execute(%named);

=head1 DESCRIPTION

A CallDispatcher service is a means by which a function call (perhaps remote)
may be made synchronously.

=cut

#############################################################################
# CLASS GROUP
#############################################################################

=head1 Class Group: CallDispatcher

The following classes might be a part of the CallDispatcher Class Group.

=over

=item * Class: App::CallDispatcher

=item * Class: App::CallDispatcher::Local

=item * Class: App::CallDispatcher::SOAP

=item * Class: App::CallDispatcher::pRPC

=item * Class: App::CallDispatcher::PlRPC

=item * Class: App::CallDispatcher::Messaging

=back

=cut

#############################################################################
# CLASS
#############################################################################

=head1 Class: App::CallDispatcher

A CallDispatcher service is a means by which a function call (perhaps remote)
may be made synchronously or asynchronously.

 * Throws: App::Exception::CallDispatcher
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
# execute()
#############################################################################

=head2 execute()

    * Signature: $procedure->execute($request, $response);
    * Signature: $response = $procedure->execute($request);
    * Signature: $response = $procedure->execute(%named);
    * Param:     $request           ref   [in]
    * Param:     $response          ref   [out]
    * Return:    $response          ref
    * Throws:    App::Exception::CallDispatcher
    * Since:     0.01

    Sample Usage: 

    $procedure->execute($request, $response);
    $response = $procedure->execute($request);
    $response = $procedure->execute(%named);

=cut

sub execute {
    my $self = shift;
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

Returns 'CallDispatcher';

    * Signature: $service_type = App::CallDispatcher->service_type();
    * Param:     void
    * Return:    $service_type  string
    * Since:     0.01

    $service_type = $cdisp->service_type();

=cut

sub service_type () { 'CallDispatcher'; }

=head1 ACKNOWLEDGEMENTS

 * Author:  Stephen Adkins <stephen.adkins@officevision.com>
 * License: This is free software. It is licensed under the same terms as Perl itself.

=head1 SEE ALSO

L<C<App::Context>|App::Context>,
L<C<App::Service>|App::Service>

=cut

1;

