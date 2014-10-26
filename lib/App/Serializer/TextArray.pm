
#############################################################################
## $Id: TextArray.pm,v 1.1 2004/02/26 16:12:50 spadkins Exp $
#############################################################################

package App::Serializer::TextArray;

use App;
use App::Serializer;
@ISA = ( "App::Serializer" );

use strict;

=head1 NAME

App::Serializer::TextArray - Interface for serialization and deserialization

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
    $text = $serializer->serialize($data);
    $data = $serializer->deserialize($text);
    print $serializer->dump($data), "\n";

=head1 DESCRIPTION

A Serializer allows you to serialize a structure of data
of arbitrary depth to a scalar and deserialize it back to the
structure.

The TextArray serializer uses a set of vertical bar ("|") delimited lines
as a way of serializing a perl array.  This serializer is only useful
for serializing arrays.

=cut

#############################################################################
# CLASS
#############################################################################

=head1 Class: App::Serializer::TextArray

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

    * Signature: $text = $serializer->serialize(@data);
    * Param:     @data             any
    * Return:    $text             text
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
    $text = $serializer->serialize($data);

=cut

sub serialize {
    my ($self, $array) = @_;
    die "Tried to serialize non-array ($array) with TextArray serializer" if (ref($array) ne "ARRAY");
    my $text = "";
    foreach my $row (@$array) {
       $text .= join("|", map { (defined $_) ? $_ : "undef" } @$row) . "\n";
    }
    return $text;
}

#############################################################################
# deserialize()
#############################################################################

=head2 deserialize()

    * Signature: @data = $serializer->deserialize($text);
    * Signature: @data = App::Serializer->deserialize($text);
    * Param:     $text          text
    * Return:    @data          any
    * Throws:    App::Exception::Serializer
    * Since:     0.01

    Sample Usage: 

    $context = App->context();
    $serializer = $context->service("Serializer");  # or ...
    $serializer = $context->serializer();
    $data = $serializer->deserialize($text);
    print $serializer->dump($data), "\n";

=cut

sub deserialize {
    my ($self, $text) = @_;
    my $array = [];
    my ($row, @rows);
    chomp($text);
    @rows = split(/\n/,$text);
    foreach my $line (@rows) {
        $row = [ map { $_ eq "undef" ? undef : $_ } split(/\|/,$line) ];
        push(@$array, $row);
    }
    return($array);
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
    'text/plain';
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

