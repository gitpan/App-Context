
#############################################################################
## $Id: XMLDumper.pm,v 1.1 2002/09/09 01:34:11 spadkins Exp $
#############################################################################

package App::Serializer::XMLDumper;

use App;
use App::Serializer;
@ISA = ( "App::Serializer" );

use strict;

=head1 NAME

App::Serializer::XMLDumper - Interface for serialization and deserialization

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
    $xml = $serializer->serialize($data);
    $data = $serializer->deserialize($xml);
    print $serializer->dump($data), "\n";

=head1 DESCRIPTION

A Serializer allows you to serialize a structure of data
of arbitrary depth to a scalar and deserialize it back to the
structure.

The XMLDumper serializer uses non-validated XML as the serialized
form of the data.  It uses the XML::Dumper class to perform
the deserialization and serialization.

=cut

#############################################################################
# CLASS
#############################################################################

=head1 Class: App::Serializer::XMLDumper

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

    * Signature: $xml = $serializer->serialize($data);
    * Param:     $data              ref
    * Return:    $xml               text
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
    $xml = $serializer->serialize($data);

=cut

use XML::Parser;
use XML::Dumper;

sub serialize {
    my ($self, $data) = @_;
    my $xp = XML::Dumper->new();
    my $xml = $xp->pl2xml_string($data);
    return $xml;
}

#############################################################################
# deserialize()
#############################################################################

=head2 deserialize()

    * Signature: $data = $serializer->deserialize($xml);
    * Signature: $data = App::Serializer->deserialize($xml);
    * Param:     $data              ref
    * Return:    $xml               text
    * Throws:    App::Exception::Serializer
    * Since:     0.01

    Sample Usage: 

    $context = App->context();
    $serializer = $context->service("Serializer");  # or ...
    $serializer = $context->serializer();
    $data = $serializer->deserialize($xml);
    print $serializer->dump($data), "\n";

=cut

sub deserialize {
    my ($self, $xml) = @_;
    my $parser = XML::Parser->new(Style => 'Tree');
    my $tree = $parser->parse($xml);
    my $xp = XML::Dumper->new();
    my $data = $xp->xml2pl($tree);
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
    'text/xml';
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

