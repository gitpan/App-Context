
#############################################################################
## $Id: Session.pm,v 1.2 2002/09/18 02:54:10 spadkins Exp $
#############################################################################

package App::Session;

use App;
use App::Reference;
@ISA = ( "App::Reference" );

use strict;

=head1 NAME

App::Session - represents a sequence of multiple events
perhaps executed in separate processes

=head1 SYNOPSIS

   # ... official way to get a Session object ...
   use App;
   $session = App->session();
   $session = $session->session();   # get the session

   # any of the following named parameters may be specified
   $session = $session->session(
   );

   # ... alternative way (used internally) ...
   use App::Session;
   $session = App::Session->new();

=cut

#############################################################################
# CONSTANTS
#############################################################################

=head1 DESCRIPTION

A Session class models the sequence of events associated with a
use of the system.  These events may occur in different processes.

For instance, in a web environment, when a new user arrives at a web site,
he is allocated a new
Session, even though he may not even be authenticated.  In subsequent
requests, his actions are tied together by a Session ID that is transmitted
from the browser to the server on each request.  During the Session, he
may log in, log out, and log in again.
Finally, Sessions in the web environment generally time out if not 
accessed for a certain period of time.

Conceptually, the Session may span processes, so they generally have a
way to persist themselves so that they may be reinstantiated wherever
they are needed.  This would certainly be true in CGI or Cmd Contexts
where each CGI request or command execution relies on and contributes
to the running state accumulated in the Session.  Other execution
Contexts (Curses, Gtk) only require trivial implementations of a Session
because it stays in memory for the duration of the process.
Nonetheless, even these Contexts use a Session object so that the
programming model across multiple platforms is the same.

=cut

#############################################################################
# CLASS GROUP
#############################################################################

=head1 Class Group: Session

The following classes might be a part of the Session Class Group.

=over

=item * Class: App::Session

=item * Class: App::Session::HTMLHidden

=item * Class: App::Session::Cookie

=item * Class: App::Session::ApacheSession

=item * Class: App::Session::ApacheSessionX

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

The constructor is inherited from
L<C<App::Service>|App::Service/"new()">.

=cut

#############################################################################
# PUBLIC METHODS
#############################################################################

=head1 Public Methods:

=cut

#############################################################################
# get_session_id()
#############################################################################

=head2 get_session_id()

The get_session_id() returns the session_id of this particular session.
This session_id is unique for all time.  If a session_id does not yet
exist, one will be created.  The session_id is only created when first
requested, and not when the session is instantiated.

    * Signature: $session_id = $session->get_session_id();
    * Param:  void
    * Return: $session_id      string
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    $session->get_session_id();

=cut

my $seq = 0;

sub get_session_id {
    my $self = shift;
    return $self->{session_id} if (defined $self->{session_id});
    my ($session_id);
    $seq++;
    $session_id = time() . ":" . $$;
    $session_id .= ":$seq" if ($seq > 1);
    $self->{session_id} = $session_id;
    $session_id;
}

#############################################################################
# html()
#############################################################################

=head2 html()

The html() method ...

    * Signature: $html = $session->html();
    * Param:  void
    * Return: $html      string
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    $session->html();

The html() method on a session may be used by Contexts which embed session
information in a web page being returned to the user's browser.
(Some contexts do not use HTML for the User Interface and will not call
this routine.)

The most common method of embedding the session information in the HTML
is to encode the session_id in an HTML hidden variable (<input type=hidden>).
That is what this implementation does.

=cut

sub html {
    my ($self, $options) = @_;
    my ($session_id, $html);
    $session_id = $self->get_session_id();
    $html = "<input type=\"hidden\" name=\"app.session_id\" value=\"$session_id\">";
    $html;
}

1;

