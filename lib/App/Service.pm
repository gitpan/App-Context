
#############################################################################
## $Id: Service.pm,v 1.1 2002/09/09 01:34:10 spadkins Exp $
#############################################################################

package App::Service;

use strict;

use App;

=head1 NAME

App::Service - Provides core methods for App-Context Services

=head1 SYNOPSIS

    use App::Service;

    # never really used, because this is a base class
    %named = (
        # named args would go here
    );
    $service = App::Service->new(%named);

=head1 DESCRIPTION

The App::Service class is a base class for all App-Context services.

    * Throws: App::Exception
    * Since:  0.01

=cut

#############################################################################
# CONSTRUCTOR METHODS
#############################################################################

=head1 Constructor Methods:

=cut

#############################################################################
# Method: new()
#############################################################################

=head2 new()

This constructor is used to create all objects which are App-Context services.
Customized behavior for a particular service is achieved by overriding
the init() method.

    * Signature: $service = App::Service->new(%named)
    * Return:    $service       App::Service
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: (never used because this is a base class, but the
    constructors of all services follow these rules)
    
    * If the number of arguments is odd, the first arg is the service name
      (otherwise, "default" is assumed)
    * If there are remaining arguments, they are variable/value pairs
    * If there are no arguments at all, the "default" name is assumed
    * If a "name" was supplied using any of these methods,
      the master config is consulted to find the config for this
      particular service instance (service_type/name).

    $service = App::Service->new();        # assumes "default" name
    $service = App::Service->new("srv1");  # instantiate named service
    $service = App::Service->new(          # "default" with named args
        arg1 => 'value1',
        arg2 => 'value2',
    );

=cut

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my ($self, $context, $type, $lcf_type);

    $context = App->context();
    $type = $class->service_type();
    $lcf_type = lcfirst($type);
    if ($#_ % 2 == 0) {  # odd number of args
        $self = $context->service($type, @_, "${lcf_type}Class", $class);
    }
    else {  # even number of args (
        $self = $context->service($type, "default", @_, "${lcf_type}Class", $class);
    }
    return $self;
}

#############################################################################
# Method: service_type()
#############################################################################

=head2 service_type()

Returns the service type (i.e. CallDispatcher, Repository, SessionObject, etc.).

    * Signature: $service_type = App::Service->service_type();
    * Param:     void
    * Return:    $service_type  string
    * Since:     0.01

    $service_type = $service->service_type();

=cut

sub service_type () { 'Service'; }

#############################################################################
# Method: content()
#############################################################################

=head2 content()

    * Signature: $content = $self->content();
    * Param:     void
    * Return:    $content   any
    * Throws:    App::Exception
    * Since:     0.01

    $content = $so->content();
    if (ref($content)) {
        App::Reference->print($content);
        print "\n";
    }
    else {
        print $content, "\n";
    }

=cut

sub content {
    my $self = shift;
    $self->internals();
}

#############################################################################
# content_type()
#############################################################################

=head2 content_type()

    * Signature: $content_type = $service->content_type();
    * Param:     void
    * Return:    $content_type   string
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    $content_type = $service->content_type();

=cut

sub content_type {
    'text/plain';
}

#############################################################################
# Method: internals()
#############################################################################

=head2 internals()

    * Signature: $guts = $self->internals();
    * Param:     void
    * Return:    $guts     {}
    * Throws:    App::Exception
    * Since:     0.01

    $guts = $so->internals();
    App::Reference->print($guts);
    print App::Reference->dump($guts), "\n";

Copy the internals of the current SessionObject to a new hash and return
a reference to that hash for debugging purposes.  The resulting hash
reference may be printed using Data::Dumper (or App::Reference).
The refe

=cut

sub internals {
    my ($self) = @_;
    my %guts = %$self;
    delete $guts{context};
    return \%guts;
}

#############################################################################
# dump()
#############################################################################

=head2 dump()

    * Signature: $perl = $service->dump();
    * Param:     void
    * Return:    $perl      text
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    $service = $context->repository();
    print $service->dump(), "\n";

=cut

use Data::Dumper;

sub dump {
    my ($self) = @_;
    my $name = $self->service_type() . "__" . $self->{name};
    my $d = Data::Dumper->new([ $self ], [ $name ]);
    $d->Indent(1);
    return $d->Dump();
}

#############################################################################
# print()
#############################################################################

=head2 print()

    * Signature: $service->print();
    * Param:     void
    * Return:    void
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    $service->print();

=cut

sub print {
    my $self = shift;
    print $self->dump();
}

#############################################################################
# PROTECTED METHODS
#############################################################################

=head1 Protected Methods:

The following methods are intended to be called by subclasses of the
current class.

=cut

#############################################################################
# Method: init()
#############################################################################

=head2 init()

The init() method is called from within the standard Service
constructor.
It allows subclasses of the Service to customize the behavior of the
constructor by overriding the init() method. 
The init() method in this class simply calls the init() 
method to allow each service instance to initialize itself.

    * Signature: init($named)
    * Param:     $named      {}   [in]
    * Return:    void
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    $service->init(\%args);

=cut

sub init {
    my ($self, $args) = @_;
}

=head1 ACKNOWLEDGEMENTS

 * Author:  Stephen Adkins <stephen.adkins@officevision.com>
 * License: This is free software. It is licensed under the same terms as Perl itself.

=head1 SEE ALSO

L<C<App>|App>,
L<C<App::Context>|App::Context>,
L<C<App::Conf>|App::Conf>

=cut

1;

