
#############################################################################
## $Id: CallDispatcher.pm,v 1.4 2004/02/27 14:12:22 spadkins Exp $
#############################################################################

package App::CallDispatcher;

use App;
use App::Service;
@ISA = ( "App::Service" );

use strict;

=head1 NAME

App::CallDispatcher - synchronous (potentially remote) call_dispatcher invocation

=head1 SYNOPSIS

    use App;

    $context = App->context();
    $call_dispatcher = $context->service("CallDispatcher");  # or ...
    $call_dispatcher = $context->call_dispatcher();

    $call_dispatcher->call($request, $response);
    $response = $call_dispatcher->call($request);
    $response = $call_dispatcher->call(%named);

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

=item * Class: App::CallDispatcher::HTTPSimple

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
# call()
#############################################################################

=head2 call()

    * Signature: @returnvals = $call_dispatcher->call($service, $name, $method, $args);
    * Param:     $service           string  [in]
    * Param:     $name              string  [in]
    * Param:     $method            string  [in]
    * Param:     $args              ARRAY   [in]
    * Return:    @returnvals        any
    * Throws:    App::Exception::CallDispatcher
    * Since:     0.01

    Sample Usage: 

    @returnvals = $call_dispatcher->call("Repository","db",
        "get_rows",["city",{city_cd=>"LAX"},["city_cd","state","country"]]);

The default call dispatcher is a local call dispatcher.
It simply passes the call() on to the local context for execution.
It results in an in-process method call rather than a remote method call.

=cut

sub call {
    my ($self, $service, $name, $method, $args) = @_;
    my $context = $self->{context};
    my @returnvals = $context->call($service, $name, $method, $args);
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
