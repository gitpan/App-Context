
#############################################################################
## $Id: Properties.pm,v 1.1 2002/09/09 01:34:11 spadkins Exp $
#############################################################################

package App::Serializer::Properties;

use App;
use App::Serializer;

@ISA = ( "App::Serializer" );

use App::Reference;

use strict;

=head1 NAME

App::Serializer::Properties - Interface for serialization and deserialization

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
    $propdata = $serializer->serialize($data);
    $data = $serializer->deserialize($propdata);
    print $serializer->dump($data), "\n";

=head1 DESCRIPTION

A Serializer allows you to serialize a structure of data
of arbitrary depth to a scalar and deserialize it back to the
structure.

The Properties serializer reads and writes data which conforms to
the standards of Java properties files.

=cut

#############################################################################
# CLASS
#############################################################################

=head1 Class: App::Serializer::Properties

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

    * Signature: $propdata = $serializer->serialize($data);
    * Param:     $data              ref
    * Return:    $propdata           text
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
    $propdata = $serializer->serialize($data);

=cut

sub serialize {
    my ($self, $data) = @_;
    $self->_serialize($data, "");
}

sub _serialize {
    my ($self, $data, $section) = @_;
    my ($section_data, $idx, $key, $elem, $prefix);
    $prefix = "";
    $prefix = "$section." if (defined $section && $section ne "");
    if (ref($data) eq "ARRAY") {
        for ($idx = 0; $idx <= $#$data; $idx++) {
            $elem = $data->[$idx];
            if (!ref($elem)) {
                $section_data .= "$prefix$idx = $elem\n";
            }
            else {
                $section_data .= $self->_serialize($elem, "$prefix$idx");
            }
        }
    }
    elsif (ref($data)) {
        foreach $key (sort keys %$data) {
            $elem = $data->{$key};
            if (!ref($elem)) {
                $section_data .= "$prefix$key = $elem\n";
            }
            else {
                $section_data .= $self->_serialize($elem, "$prefix$key");
            }
        }
    }

    return $section_data;
}

#############################################################################
# deserialize()
#############################################################################

=head2 deserialize()

    * Signature: $data = $serializer->deserialize($propdata);
    * Signature: $data = App::Serializer->deserialize($propdata);
    * Param:     $data              ref
    * Return:    $propdata           text
    * Throws:    App::Exception::Serializer
    * Since:     0.01

    Sample Usage: 

    $context = App->context();
    $serializer = $context->service("Serializer");  # or ...
    $serializer = $context->serializer();
    $data = $serializer->deserialize($propdata);
    print $serializer->dump($data), "\n";

=cut

sub deserialize {
    my ($self, $propdata) = @_;
    my ($data, $r, $line, $attrib, $value);

    $r = App::Reference->new(); # dummy ref (shorthand for static calls)
    $data = {};

    foreach $line (split(/\n/, $propdata)) {
        next if ($line =~ /^#/);  # ignore comments
        if ($line =~ /^ *([^ =]+) *= *(.*)$/) {
            $attrib = $1;
            $value = $2;
            $r->set($attrib, $value, $data);
        }
    }

    return $data;
}

#############################################################################
# dump()
#############################################################################

=head2 dump()

The constructor is inherited from
L<C<App::Serializer>|App::Serializer/"dump()">.

=head1 ACKNOWLEDGEMENTS

 * Author:  Stephen Adkins <stephen.adkins@officevision.com>
 * License: This is free software. It is licensed under the same terms as Perl itself.

=head1 SEE ALSO

L<C<App::Context>|App::Context>,
L<C<App::Service>|App::Service>

=cut

1;

