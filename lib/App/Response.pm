
#############################################################################
## $Id: Response.pm,v 1.7 2005/08/09 19:04:07 spadkins Exp $
#############################################################################

package App::Response;

use strict;

use App;

=head1 NAME

App::Response - the response

=head1 SYNOPSIS

   # ... official way to get a Response object ...
   use App;
   $context = App->context();
   $response = $context->response();  # get the response

   # ... alternative way (used internally) ...
   use App::Response;
   $response = App::Response->new();

=cut

#############################################################################
# CONSTANTS
#############################################################################

=head1 DESCRIPTION

A Response class ...

=cut

#############################################################################
# CLASS GROUP
#############################################################################

=head1 Class Group: Response

The following classes might be a part of the Response Class Group.

=over

=item * Class: App::Response

=item * Class: App::Response::CGI

=back

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

The App::Response->new() method is rarely called directly.
That is because the current response is usually accessed through the
$context object.

    * Signature: $response = App::Response->new(%named);
    * Return: $response     App::Response
    * Throws: App::Exception
    * Since:  0.01

    Sample Usage: 

    $response = App::Response->new();

=cut

sub new {
    &App::sub_entry if ($App::trace);
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless $self, $class;

    my $context = shift;
    $self->{context} = $context;

    my $args = shift || {};
    $self->_init($args);

    &App::sub_exit($self) if ($App::trace);
    return $self;
}

#############################################################################
# PROTECTED METHODS
#############################################################################

=head1 Protected Methods:

The following methods are intended to be called by subclasses of the
current class (or environmental, "main" code).

=cut

#############################################################################
# _init()
#############################################################################

=head2 _init()

The _init() method is called from within the standard Response constructor.
The _init() method in this class does nothing.
It allows subclasses of the Response to customize the behavior of the
constructor by overriding the _init() method. 

    * Signature: $response->_init()
    * Param:     void
    * Return:    void
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    $response->_init();

=cut

sub _init {
    &App::sub_entry if ($App::trace);
    my ($self, $args) = @_;
    &App::sub_exit() if ($App::trace);
}

#############################################################################
# PUBLIC METHODS
#############################################################################

=head1 Public Methods

=cut

#############################################################################
# content_type()
#############################################################################

=head2 content_type()

The content_type() method ...

    * Signature: $content_type = $response->content_type();
    * Signature: $response->content_type($content_type);
    * Param:  $content_type         string
    * Return: $content_type         string
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    $content_type = $response->content_type();

=cut

sub content_type {
    &App::sub_entry if ($App::trace);
    my ($self, $content_type) = @_;
    if (defined $content_type) {
        $self->{content_type} = $content_type;
    }
    &App::sub_exit($self->{content_type}) if ($App::trace);
    return $self->{content_type};
}

#############################################################################
# content()
#############################################################################

=head2 content()

The content() method ...

    * Signature: $content = $response->content();
    * Signature: $response->content($content);
    * Param:  $content         any
    * Return: $content         any
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    $content = $response->content();

=cut

sub content {
    &App::sub_entry if ($App::trace);
    my ($self, $content) = @_;
    if (defined $content) {
        $self->{content} = $content;
    }
    &App::sub_exit($self->{content}) if ($App::trace);
    return $self->{content};
}

sub include {
    &App::sub_entry if ($App::trace);
    my ($self, $type, $content) = @_;
    if (!$self->{include}{$type}{$content}) {
        if (!$self->{include}{"${type}_list"}) {
            $self->{include}{"${type}_list"} = [ $content ];
        }
        else {
            push(@{$self->{include}{"${type}_list"}}, $content);
        }
        $self->{include}{$type}{$content} = 1;
    }
    &App::sub_exit() if ($App::trace);
}

sub is_included {
    &App::sub_entry if ($App::trace);
    my ($self, $type, $content) = @_;
    my $included = $self->{include}{$type}{$content};
    &App::sub_exit($included) if ($App::trace);
    return($included);
}

1;

