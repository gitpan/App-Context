
#############################################################################
## $Id: HTMLHidden.pm,v 1.2 2002/09/18 02:54:11 spadkins Exp $
#############################################################################

package App::Session::HTMLHidden;

use App;
use App::Session;
@ISA = ( "App::Session" );

use strict;

use Data::Dumper;
use Storable qw(freeze thaw);
use Compress::Zlib;
use MIME::Base64;

# note: We may want to apply an HMAC (hashed message authentication code)
#       so that users cannot fiddle with the values.
#       We may also want to add IP address and timeout for security.
#       We may also want to add encryption so they can't even decode the data.
# use Digest::HMAC_MD5;
# use Crypt::CBC;

=head1 NAME

App::Session::HTMLHidden - a session whose state is maintained across
HTML requests by being embedded in an HTML <input type="hidden"> tag.

=head1 SYNOPSIS

   # ... official way to get a Session object ...
   use App;
   $session = App->session();
   $session = $session->session();   # get the session

   # any of the following named parameters may be specified
   $session = $session->session(
   );

   # ... alternative way (used internally) ...
   use App::Session::HTMLHidden;
   $session = App::Session->new();

=cut

#############################################################################
# CONSTANTS
#############################################################################

=head1 DESCRIPTION

A Session class models the sequence of events associated with a
use of the system.  These events may occur in different processes.
Yet the accumulated state of the session needs to be propagated from
one process to the next.

This Session::HTMLHidden maintains its state across
HTML requests by being embedded in an HTML <input type="hidden"> tag.
As a result, it requires no server-side storage, so the sessions
never need to time out.

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
    "embedded";
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

=cut

sub html {
    my ($self) = @_;
    my ($sessiontext, $sessiondata, $html, $initconf);

    $sessiondata = $self->{store};
    $sessiontext = encode_base64(Compress::Zlib::memGzip(freeze($sessiondata)));

    my ($maxvarsize, $maxvarlines);
    $maxvarlines = 24;
    $maxvarsize = $maxvarlines*77;  # length of a MIME/Base64 line is (76 chars + newline)

    if (length($sessiontext) <= $maxvarsize) {
        $html = "<input type=\"hidden\" name=\"app.sessiondata\" value=\"\n$sessiontext\">";
    }
    else {
        my (@sessiontext, $i, $startidx, $endidx, $textchunk);
        @sessiontext = split(/\n/,$sessiontext);
        $i = 1;
        $startidx = 0;
        $endidx = $startidx+$maxvarlines-1;
        $textchunk = join("\n",@sessiontext[$startidx .. $endidx]);
        $html = "<input type=\"hidden\" name=\"app.sessiondata\" value=\"\n$textchunk\n\">";
        while ($endidx < $#sessiontext) {
            $i++;
            $startidx += $maxvarlines;
            $endidx = $startidx+$maxvarlines-1;
            $endidx = $#sessiontext if ($endidx > $#sessiontext-1);
            $textchunk = join("\n",@sessiontext[$startidx .. $endidx]);
            $html .= "\n<input type=\"hidden\" name=\"app.sessiondata${i}\" value=\"\n$textchunk\n\">";
        }
    }
    $html .= "\n";

    $initconf = $self->{context}->initconf();
    if ($initconf && $initconf->{showsession}) {
        # Debugging Only
        my $d = Data::Dumper->new([ $sessiondata ], [ "session_store" ]);
        $d->Indent(1);
        $html .= "<!-- Contents of the session. (For debugging only. Should be turned off in production.)\n";
        $html .= $d->Dump();
        $html .= "-->\n";
    }

    $html;
}

#############################################################################
# PROTECTED METHODS
#############################################################################

=head1 Protected Methods:

The following methods are intended to be called by subclasses of the
current class.

=cut

#############################################################################
# create()
#############################################################################

=head2 create()

The create() method is used to create the Perl structure that will
be blessed into the class and returned by the constructor.

    * Signature: $ref = App::Reference->create($hashref)
    * Param:     $hashref            {}
    * Return:    $ref                ref
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage:

=cut

sub create {
    my ($self, $args) = @_;
    $args = {} if (!defined $args);

    my ($ref);
    $ref = {};

    $ref;
}

#############################################################################
# init()
#############################################################################

=head2 init()

The init() method is called from within the constructor.

    * Signature: init($named)
    * Param:     $named        {}    [in]
    * Return:    void
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    $ref->init($args);

The init() method looks at the CGI variables in the request
and restores the session state information from the variable
named "app.sessiondata" (and "app.sessiondata[2..n]").

When the values of these variables are concatenated, they
form a Base64-encoded, gzipped, frozen multi-level hash of
session state data.  To retrieve the state data, the text
is therefore decoded, gunzipped, and thawed (a la Storable).

TODO: encrypt and MAC

=cut

sub init {
    my ($self, $args) = @_;
    my ($cgi, $sessiontext, $store);

    $cgi = $args->{cgi} if (defined $args);
    $store = {};
    if (defined $cgi) {
        $sessiontext = $cgi->param("app.sessiondata");
        if ($sessiontext) {
            my ($i, $textchunk);
            $i = 2;
            while (1) {
                $textchunk = $cgi->param("app.sessiondata${i}");
                last if (!$textchunk);
                $sessiontext .= $textchunk;
                $i++;
            }
            $store = thaw(Compress::Zlib::memGunzip(decode_base64($sessiontext)));
        }
    }
    $self->{context} = $args->{context} if (defined $args->{context});
    $self->{store} = $store;
    $self->{cache} = {};
}

1;

