
#############################################################################
## $Id: Yaml.pm 3334 2004-02-26 16:12:50Z spadkins $
#############################################################################

package App::Serializer::Yaml;

use App;
use App::Serializer;
@ISA = ( "App::Serializer" );

use strict;

=head1 NAME

App::Serializer::Yaml - Interface for serialization and deserialization

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
    $yaml = $serializer->serialize($data);
    $data = $serializer->deserialize($yaml);
    print $serializer->dump($data), "\n";

=head1 DESCRIPTION

A Serializer allows you to serialize a structure of data
of arbitrary depth to a scalar and deserialize it back to the
structure.

The Yaml serializer uses YAML as the serialized
form of the data.  It uses the "YAML.pm" module from CPAN to perform
the deserialization and serialization.

=cut

#############################################################################
# CLASS
#############################################################################

=head1 Class: App::Serializer::Yaml

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

    * Signature: $yaml = $serializer->serialize(@data);
    * Param:     @data             any
    * Return:    $yaml             text
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
    $yaml = $serializer->serialize($data);

=cut

use YAML;

sub serialize {
    my ($self, $data) = @_;
    my ($yaml);
    if (ref($data) eq "ARRAY") {
        $yaml = Dump(@$data);
    }
    else {
        $yaml = Dump($data);
    }
    return $yaml;
}

#############################################################################
# deserialize()
#############################################################################

=head2 deserialize()

    * Signature: @data = $serializer->deserialize($yaml);
    * Signature: @data = App::Serializer->deserialize($yaml);
    * Param:     $yaml          text
    * Return:    @data          any
    * Throws:    App::Exception::Serializer
    * Since:     0.01

    Sample Usage: 

    $context = App->context();
    $serializer = $context->service("Serializer");  # or ...
    $serializer = $context->serializer();
    $data = $serializer->deserialize($yaml);
    print $serializer->dump($data), "\n";

=cut

sub deserialize {
    my ($self, $yaml) = @_;
    my (@data) = Load($yaml);
    if ($#data > 0) {
        return(\@data);
    }
    else {
        return($data[0]);
    }
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
    'text/yaml';
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

