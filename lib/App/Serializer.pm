
#############################################################################
## $Id: Serializer.pm,v 1.1 2002/09/09 01:34:10 spadkins Exp $
#############################################################################

package App::Serializer;

use App;
use App::Service;
@ISA = ( "App::Service" );

use Data::Dumper;
# use Compress::Zlib;
# use MIME::Base64;
# use Digest::HMAC_MD5;
# use Crypt::CBC;

use strict;

=head1 NAME

App::Serializer - Interface for serialization and deserialization

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
    $serialized_data = $serializer->serialize($data);
    $data = $serializer->deserialize($serialized_data);
    print $serializer->dump($data), "\n";

=head1 DESCRIPTION

A Serializer is a means by which a structure of data of arbitrary depth
may be serialized or deserialized.

Serializers may be used for configuration files, data persistence, or
transmission of data across a network.

Serializers include the ability to compress, encrypt, and/or MIME
the serialized data.  (These are all scalar-to-scalar transformations.)

=cut

#############################################################################
# CLASS GROUP
#############################################################################

=head1 Class Group: Serializer

The following classes might be a part of the Serializer Class Group.

=over

=item * Class: App::Serializer

=item * Class: App::Serializer::Storable

=item * Class: App::Serializer::XMLSimple

=item * Class: App::Serializer::XML

=item * Class: App::Serializer::Ini

=item * Class: App::Serializer::Properties

=back

=cut

#############################################################################
# CLASS
#############################################################################

=head1 Class: App::Serializer

A Serializer serves to serialize and deserialize perl data structures
of arbitrary depth.
The base class serializes the data as Perl code using Data::Dumper.
(This behavior is overridden with customized serialization techniques
by the derived subclasses.)

 * Throws: App::Exception::Serializer
 * Since:  0.01

=head2 Class Design

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

    * Signature: $serialized_data = $serializer->serialize($data);
    * Param:     $data              ref
    * Return:    $serialized_data   binary
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
    $serialized_data = $serializer->serialize($data);

=cut

sub serialize {
    my ($self, $data) = @_;
    $self->dump($data);
}

#############################################################################
# deserialize()
#############################################################################

=head2 deserialize()

    * Signature: $serialized_data = $serializer->deserialize($data);
    * Signature: $serialized_data = App::Serializer->deserialize($data);
    * Param:     $data              ref
    * Return:    $serialized_data   binary
    * Throws:    App::Exception::Serializer
    * Since:     0.01

    Sample Usage: 

    $context = App->context();
    $serializer = $context->service("Serializer");  # or ...
    $serializer = $context->serializer();
    $data = $serializer->deserialize($serialized_data);
    print $serializer->dump($data), "\n";

=cut

sub deserialize {
    my ($self, $serialized_data) = @_;
    my ($data, $serializer_class);
    $data = {};
    $serializer_class = "";

    if ($self eq "App::Serializer") {  # static method call

        if ($serialized_data =~ s/#Serializer +([^ ]+) +\((.*)\)\n//) {
            $serializer_class = $1;
        }
        elsif ($serialized_data =~ /^<!DOCTYPE/i) {
            $serializer_class = "App::Serializer::XML";
        }
        elsif ($serialized_data =~ /^</) {
            $serializer_class = "App::Serializer::XMLSimple";
        }
    }

    if ($serializer_class) {
        eval "use $serializer_class;";
        if ($@) {
            App::Exception::Serializer->throw(
                error => "create(): error loading $serializer_class serializer class\n"
            );
        }
        $data = $serializer_class->deserialize($serialized_data);
    }
    else {
        if ($serialized_data =~ /^\$[a-zA-Z][a-zA-Z0-9_]* *= *(.*)$/s) {
            $serialized_data = "\$data = $1";   # untainted now
            eval($serialized_data);
            die "Deserialization Error: $@" if ($@);
        }
        else {
            die "Deserialization Error: Data didn't have \"\$var = {...};\" or \"\$var = [ ... ];\" format.";
        }
    }

    $data;
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

    * Signature: $perl = $serializer->dump($data);
    * Param:     $data      ref
    * Return:    $perl      text
    * Throws:    App::Exception::Serializer
    * Since:     0.01

    Sample Usage: 

    $context = App->context();
    $serializer = $context->service("Serializer");  # or ...
    $serializer = $context->serializer();
    $data = $serializer->deserialize($serialized_data);
    print $serializer->dump($data), "\n";

=cut

sub dump {
    my ($self, $data) = @_;
    my $d = Data::Dumper->new([ $data ], [ "data" ]);
    $d->Indent(1);
    return $d->Dump();
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

Returns 'Serializer';

    * Signature: $service_type = App::Serializer->service_type();
    * Param:     void
    * Return:    $service_type  string
    * Since:     0.01

    $service_type = $serializer->service_type();

=cut

sub service_type () { 'Serializer'; }

=head1 ACKNOWLEDGEMENTS

 * Author:  Stephen Adkins <stephen.adkins@officevision.com>
 * License: This is free software. It is licensed under the same terms as Perl itself.

=head1 SEE ALSO

L<C<App::Context>|App::Context>,
L<C<App::Service>|App::Service>

=cut

1;

