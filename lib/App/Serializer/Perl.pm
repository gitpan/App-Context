
#############################################################################
## $Id: Perl.pm 3348 2004-02-27 16:19:41Z spadkins $
#############################################################################

package App::Serializer::Perl;

use App;
use App::Serializer;
@ISA = ( "App::Serializer" );

use strict;

=head1 NAME

App::Serializer::Perl - Interface for serialization and deserialization

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
    $perl = $serializer->serialize($data);
    $data = $serializer->deserialize($perl);
    print $serializer->dump($data), "\n";

=head1 DESCRIPTION

A Serializer allows you to serialize a structure of data
of arbitrary depth to a scalar and deserialize it back to the
structure.

The Perl serializer uses perl data structure syntax as the serialized
form of the data.  It uses the Data::Dumper module from CPAN to perform
the deserialization and serialization.

=cut

use Data::Dumper;

sub serialize {
    my ($self, $data) = @_;
    my ($d, $perl);
    
    $d = Data::Dumper->new([ $data ], [ "data" ]);
    $d->Indent(1);
    $perl = $d->Dump();

    return $perl;
}

sub deserialize {
    my ($self, $perl) = @_;
    my ($data);
    $perl =~ s/^\$([_a-zA-Z][_a-zA-Z0-9]*) *=/\$data =/;
    eval $perl;
    $data = $@ if ($@);
    return($data);
}

sub serialized_content_type {
    'text/perl';
}

1;

