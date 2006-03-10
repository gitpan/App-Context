
#############################################################################
## $Id: Request.pm 3360 2004-09-02 20:56:51Z spadkins $
#############################################################################

package App::Request;

use strict;

use App;

=head1 NAME

App::Request - the request

=head1 SYNOPSIS

   # ... official way to get a Request object ...
   use App;
   $context = App->context();
   $request = $context->request();  # get the request

   # ... alternative way (used internally) ...
   use App::Request;
   $request = App::Request->new();

=cut

#############################################################################
# CONSTANTS
#############################################################################

=head1 DESCRIPTION

A Request class ...

=cut

#############################################################################
# CLASS GROUP
#############################################################################

=head1 Class Group: Request

The following classes might be a part of the Request Class Group.

=over

=item * Class: App::Request

=item * Class: App::Request::CGI

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

The App::Request->new() method is rarely called directly.
That is because the current request is usually accessed through the
$context object.

    * Signature: $request = App::Request->new($context, $named);
    * Return: $request     App::Request
    * Throws: App::Exception
    * Since:  0.01

    Sample Usage: 

    $request = App::Request->new();

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

The _init() method is called from within the standard Request constructor.
The _init() method in this class does nothing.
It allows subclasses of the Request to customize the behavior of the
constructor by overriding the _init() method. 

    * Signature: $request->_init()
    * Param:     void
    * Return:    void
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    $request->_init();

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
# user()
#############################################################################

=head2 user()

The user() method returns the username of the authenticated user.
The special name, "guest", refers to the unauthenticated (anonymous) user.

    * Signature: $username = $request->user();
    * Param:  void
    * Return: string
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    $username = $request->user();

=cut

sub user {
    &App::sub_entry if ($App::trace);
    my $self = shift;
    &App::sub_exit("guest") if ($App::trace);
    "guest";
}

#############################################################################
# get_session_id()
#############################################################################

=head2 get_session_id()

The get_session_id() method returns the session_id in the request.

    * Signature: $session_id = $request->get_session_id();
    * Param:  void
    * Return: $session_id     string
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    $session_id = $request->get_session_id();

=cut

sub get_session_id {
    &App::sub_entry if ($App::trace);
    my $self = shift;
    &App::sub_exit("default") if ($App::trace);
    "default";
}

1;
