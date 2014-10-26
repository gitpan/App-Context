
#############################################################################
## $Id: ValueDomain.pm 3345 2004-02-27 14:25:10Z spadkins $
#############################################################################

package App::ValueDomain;

use App;
use App::Service;
@ISA = ( "App::Service" );

use strict;

=head1 NAME

App::ValueDomain - Interface for sharing data between processes

=head1 SYNOPSIS

    use App;

    $context = App->context();
    $dom = $context->service("ValueDomain");
    $dom = $context->value_domain();

=head1 DESCRIPTION

A ValueDomain service represents a single hash in which scalars or
deep references may be stored (basically an MLDBM).

=cut

#############################################################################
# CLASS GROUP
#############################################################################

=head1 Class Group: ValueDomain

The following classes might be a part of the ValueDomain Class Group.

=over

=item * Class: App::ValueDomain

=item * Class: App::ValueDomain::SharedDatastore

=item * Class: App::ValueDomain::Repository

=back

=cut

#############################################################################
# CLASS
#############################################################################

=head1 Class: App::ValueDomain

A ValueDomain service represents an array of values and the labels by which
those values may be displayed.

 * Throws: App::Exception::ValueDomain
 * Since:  0.01

=cut

#############################################################################
# PUBLIC METHODS
#############################################################################

=head1 Public Methods:

=cut

#############################################################################
# values()
#############################################################################

=head2 values()

    * Signature: $values = $dom->values();
    * Signature: $values = $dom->values($values_string);
    * Param:     $values_string     string
    * Return:    $values            HASH
    * Throws:    App::Exception::ValueDomain
    * Since:     0.01

    Sample Usage: 

    $context = App->context();
    $dom = $context->value_domain("product_type");
    $values = $dom->values();
    print @$values, "\n";

=cut

sub values {
    my ($self, $values_string) = @_;
    &App::sub_entry if ($App::trace);
    $self->_load($values_string);
    &App::sub_exit($self->{values}) if ($App::trace);
    return($self->{values});
}

#############################################################################
# labels()
#############################################################################

=head2 labels()

    * Signature: $labels = $dom->labels();
    * Signature: $labels = $dom->labels($values_string);
    * Param:     $values_string     string
    * Return:    $labels            HASH
    * Throws:    App::Exception::ValueDomain
    * Since:     0.01

    Sample Usage: 

    $context = App->context();
    $dom = $context->value_domain("product_type");
    $labels = $dom->labels();
    print %$labels, "\n";

=cut

sub labels {
    my ($self, $values_string) = @_;
    &App::sub_entry if ($App::trace);
    $self->_load($values_string);
    &App::sub_exit($self->{labels}) if ($App::trace);
    return($self->{labels});
}

#############################################################################
# values_labels()
#############################################################################

=head2 values_labels()

    * Signature: ($values, $labels) = $dom->values_labels();
    * Signature: ($values, $labels) = $dom->values_labels($values_string);
    * Param:     $values_string     string
    * Return:    $values            HASH
    * Return:    $labels            HASH
    * Throws:    App::Exception::ValueDomain
    * Since:     0.01

    Sample Usage: 

    $context = App->context();
    $dom = $context->value_domain("product_type");
    ($values, $labels) = $dom->values_labels();
    foreach $value (@$values) {
        print "$value => $labels->{$value}\n";
    }

=cut

sub values_labels {
    my ($self, $values_string) = @_;
    &App::sub_entry if ($App::trace);
    $self->_load($values_string);
    &App::sub_exit($self->{values}, $self->{labels}) if ($App::trace);
    return($self->{values}, $self->{labels});
}

#############################################################################
# _load()
#############################################################################

=head2 _load()

The _load() method is called to get the list of valid values in a data
domain and the labels that should be used to represent these values to
a user.

    * Signature: $self->_load()
    * Signature: $self->_load($values_string)
    * Param:     $values_string    string
    * Return:    void
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    $self->_load();

=cut

sub _load {
    &App::sub_entry if ($App::trace);
    my ($self, $values_string) = @_;
    $self->{values} = [] if (!$self->{values});
    my $values = $self->{values};
    $self->{labels} = {} if (!$self->{labels});
    my $labels = $self->{labels};
    foreach my $value (@$values) {
        $labels->{$value} = $value if (!defined $labels->{$value});
    }
    &App::sub_exit() if ($App::trace);
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

Returns 'ValueDomain';

    * Signature: $service_type = App::ValueDomain->service_type();
    * Param:     void
    * Return:    $service_type  string
    * Since:     0.01

    $service_type = $sdata->service_type();

=cut

sub service_type () { 'ValueDomain'; }

=head1 ACKNOWLEDGEMENTS

 * Author:  Stephen Adkins <stephen.adkins@officevision.com>
 * License: This is free software. It is licensed under the same terms as Perl itself.

=head1 SEE ALSO

L<C<App::Context>|App::Context>,
L<C<App::Service>|App::Service>

=cut

1;

