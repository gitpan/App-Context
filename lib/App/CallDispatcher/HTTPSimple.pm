
#############################################################################
## $Id: HTTPSimple.pm 3341 2004-02-27 14:18:30Z spadkins $
#############################################################################

package App::CallDispatcher::HTTPSimple;

use App;
use App::Service;
@ISA = ( "App::Service" );

use strict;

=head1 NAME

App::CallDispatcher::HTTPSimple - synchronous rpc using simple HTTP protocol

=head1 SYNOPSIS

    use App;

    $context = App->context();
    $call_dispatcher = $context->service("CallDispatcher");  # or ...
    $call_dispatcher = $context->call_dispatcher();

    @returnvals = $call_dispatcher->call($service, $name, $method, $args);

=head1 DESCRIPTION

A CallDispatcher service facilitates synchronous remote procedure calls.
The HTTPSimple does this by formatting a simple HTTP request using GET
or POST and parsing the results using a serializer.

=cut

#############################################################################
# CLASS
#############################################################################

=head1 Class: App::CallDispatcher::HTTPSimple

A CallDispatcher service facilitates synchronous remote procedure calls.
The HTTPSimple does this by formatting a simple HTTP request using GET
or POST and parsing the results using a serializer.

 * Throws: App::Exception::CallDispatcher
 * Since:  0.01

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

=cut

sub call {
    my ($self, $service, $name, $method, $args) = @_;
    my $context = $self->{context};
    my @returnvals = $context->call($service, $name, $method, $args);
}

=head1 ACKNOWLEDGEMENTS

 * Author:  Stephen Adkins <stephen.adkins@officevision.com>
 * License: This is free software. It is licensed under the same terms as Perl itself.

=head1 SEE ALSO

L<C<App::Context>|App::Context>,
L<C<App::Service>|App::Service>

=cut

1;

