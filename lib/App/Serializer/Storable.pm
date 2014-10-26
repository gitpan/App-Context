
#############################################################################
## $Id: Storable.pm 3255 2003-03-22 04:04:37Z spadkins $
#############################################################################

package App::Serializer::Storable;

use App;
use App::Serializer;
@ISA = ( "App::Serializer" );

use strict;

=head1 NAME

App::Serializer::Storable - Interface for serialization and deserialization

=head1 SYNOPSIS

    use App;

    $context = App->context();
    $serializer = $context->service("Serializer");  # or ...
    $serializer = $context->serializer();
    $data = {
        an => 'arbitrary',
        collection => [ 'of', 'data', ],
        of => {
            arbitrary => 'depth',
        },
    };
    $stor = $serializer->serialize($data);
    $data = $serializer->deserialize($stor);
    print $serializer->dump($data), "\n";

=head1 DESCRIPTION

A Serializer allows you to serialize a structure of data
of arbitrary depth to a scalar and deserialize it back to the
structure.

The Storable serializer uses
the Storable class to perform
the deserialization and serialization.

=cut

#############################################################################
# CLASS
#############################################################################

=head1 Class: App::Serializer::Storable

 * Throws: App::Exception::Serializer
 * Since:  0.01

=head2 Design

The class is entirely made up of static (class) methods.
However, they are each intended to be
called as methods on the instance itself.

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
# serialize()
#############################################################################

=head2 serialize()

    * Signature: $stor = $serializer->serialize($data);
    * Param:     $data              ref
    * Return:    $stor              binary
    * Throws:    App::Exception::Serializer
    * Since:     0.01

    Sample Usage: 

    $context = App->context();
    $serializer = $context->service("Serializer");  # or ...
    $serializer = $context->serializer();
    $data = {
        an => 'arbitrary',
        collection => [ 'of', 'data', ],
        of => {
            arbitrary => 'depth',
        },
    };
    $stor = $serializer->serialize($data);

=cut

use Storable qw(freeze thaw);

sub serialize {
    my ($self, $data) = @_;
    my ($stor);

    $stor = freeze($data);

    return $stor;
}

#############################################################################
# deserialize()
#############################################################################

=head2 deserialize()

    * Signature: $data = $serializer->deserialize($stor);
    * Signature: $data = App::Serializer->deserialize($stor);
    * Param:     $data              ref
    * Return:    $stor              binary
    * Throws:    App::Exception::Serializer
    * Since:     0.01

    Sample Usage: 

    $context = App->context();
    $serializer = $context->service("Serializer");  # or ...
    $serializer = $context->serializer();
    $data = $serializer->deserialize($stor);
    print $serializer->dump($data), "\n";

=cut

sub deserialize {
    my ($self, $stor) = @_;
    my ($data);

    $data = thaw($stor);

    return $data;
}

#############################################################################
# serialized_content_type()
#############################################################################

=head2 serialized_content_type()

    * Signature: $serialized_content_type = $service->serialized_content_type();
    * Param:     void
    * Return:    $serialized_content_type   string
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    $serialized_content_type = $service->serialized_content_type();

=cut

sub serialized_content_type {
    #'application/octet-stream';   # probably should be this
    'text/plain';                 # use this for now
}

#############################################################################
# dump()
#############################################################################

=head2 dump()

This method is inherited from
L<C<App::Serializer>|App::Serializer/"dump()">.

=head1 ACKNOWLEDGEMENTS

 * Author:  Stephen Adkins <stephen.adkins@officevision.com>
 * License: This is free software. It is licensed under the same terms as Perl itself.

=head1 SEE ALSO

L<C<App::Context>|App::Context>,
L<C<App::Service>|App::Service>

=cut

1;

