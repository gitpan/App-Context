
#############################################################################
## $Id: Cookie.pm,v 1.7 2003/12/03 16:18:50 spadkins Exp $
#############################################################################

package App::Session::Cookie;

use App;
use App::Session;
@ISA = ( "App::Session" );

use strict;

use Data::Dumper;
use Storable qw(freeze thaw);
use Compress::Zlib;
use MIME::Base64 ();

# note: We may want to apply an HMAC (hashed message authentication code)
#       so that users cannot fiddle with the values.
#       We may also want to add IP address and timeout for security.
#       We may also want to add encryption so they can't even decode the data.
# use Digest::HMAC_MD5;
# use Crypt::CBC;

=head1 NAME

App::Session::Cookie - a session whose state is maintained across
HTML requests by being embedded in an HTTP cookie.

=head1 SYNOPSIS

   # ... official way to get a Session object ...
   use App;
   $session = App->session();
   $session = $session->session();   # get the session

   # any of the following named parameters may be specified
   $session = $session->session(
   );

   # ... alternative way (used internally) ...
   use App::Session::Cookie;
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

This Session::Cookie maintains its state across
HTML requests by being embedded in an HTTP cookie.
As a result, it requires no server-side storage, so the sessions
never need to time out.

The Session::Cookie has an advantage over Session::HTMLHidden in that
data does not need to be posted to a URL for the session data to be
transmitted to it.  This allows that the state can be propagated
properly to sub-components of an HTML page such as

 * frame documents within a frameset (<frame src=...>)
 * dynamically generated images (<img src=...>, <input type=image src=...>)

Limits on cookie storage are as follows, according to "Dynamic HTML,
The Definitive Reference" by O'Reilly in the DOM Reference under
"document.cookie".

 * max 2000 chars per cookie (recommended, although 4000 supposedly allowed)
 * max 20 cookies per domain
 
This allows for roughly 40K of session storage.
It is quite conceivable that this amount of storage could be overrun,
so Session::Cookie is only appropriate in situations where you are confident
it will not be.  Also, session_objects should take care to clean up after themselves,
and static values stored in the session can alternatively be provided in
the config.

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

    * Signature: $session_id = $session->get_session_id();
    * Param:  void
    * Return: $session_id      string
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    $session->get_session_id();

The get_session_id() returns the session_id of this particular session.
This session_id is unique for all time.  If a session_id does not yet
exist, one will be created.  The session_id is only created when first
requested, and not when the session is instantiated.

=cut

sub get_session_id {
    my $self = shift;
    "cookie";
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

This method returns the empty string ("") as the HTML to be embedded in
the page.  This is because a session_id does not need to be stored.
However, it has the side effect that cookies are prepared for the HTTP
response headers.

=cut

sub html {
    my ($self) = @_;
    my ($sessiontext, $sessiondata, $html, $headers, $cookieoptions, $sessiontemp, $options);

    $sessiondata = $self->{store};
    $sessiontext = MIME::Base64::encode(Compress::Zlib::memGzip(freeze($sessiondata)));
    $sessiontemp = $sessiontext;
    $options = $self->{context}->options();

    my ($maxvarsize, $maxvarlines);
    # length of a MIME/Base64 line is (76 chars + newline)
    # the max length of a cookie should be 2000 chars (although the Netscape spec is 4k per cookie)
    $maxvarlines = 25;
    $maxvarsize = $maxvarlines*77;  # 1925 chars
    $headers = "";
    $cookieoptions = ""; # TODO: expires, path, domain, secure
    $html = "";

    if (length($sessiontext) <= $maxvarsize) {
        $sessiontext =~ s/\n//g;  # get rid of newlines (76 char lines)
        $headers = "Set-Cookie: app_sessiondata=$sessiontext$cookieoptions\n";
        $self->{context}->set_header($headers);
    }
    else {
        my (@sessiontext, $i, $startidx, $endidx, $textchunk);
        @sessiontext = split(/\n/,$sessiontext);
        $i = 1;
        $startidx = 0;
        $endidx = $startidx+$maxvarlines-1;
        $textchunk = join("",@sessiontext[$startidx .. $endidx]);
        $headers .= "Set-Cookie: app_sessiondata=$textchunk$cookieoptions\n";
        while ($endidx < $#sessiontext) {
            $i++;
            $startidx += $maxvarlines;
            $endidx = $startidx+$maxvarlines-1;
            $endidx = $#sessiontext if ($endidx > $#sessiontext-1);
            $textchunk = join("",@sessiontext[$startidx .. $endidx]);
            $headers .= "Set-Cookie: app_sessiondata${i}=$textchunk$cookieoptions\n";
        }
        $self->{context}->set_header($headers);
    }

    if ($options && $options->{showsession}) {
        # Debugging Only
        my $d = Data::Dumper->new([ $sessiondata ], [ "sessiondata" ]);
        $d->Indent(1);
        $html .= "<!-- Contents of the session. (For debugging only. Should be turned off in production.)\n";
        $html .= $sessiontemp;
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
# _init()
#############################################################################

=head2 _init()

The _init() method is called from within the constructor.

    * Signature: _init($named)
    * Param:     $named        {}    [in]
    * Return:    void
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    $ref->_init($args);

The _init() method looks at the cookies in the request
and restores the session state information from the cookies
named "app_sessiondata" (and "app_sessiondata[2..n]").

When the values of these cookies are concatenated, they
form a Base64-encoded, gzipped, frozen multi-level hash of
session state data.  To retrieve the state data, the text
is therefore decoded, gunzipped, and thawed (a la Storable).

Notes on length of cookies: See

  http://developer.netscape.com/docs/manuals/js/client/jsref/cookies.htm

An excerpt is included here.

The Navigator can receive and store the following:

 * 300 total cookies 
 * 4 kilobytes per cookie, where the name and the OPAQUE_STRING
   combine to form the 4 kilobyte limit. 
 * 20 cookies per server or domain. Completely specified hosts
   and domains are considered separate entities, and each has
   a 20 cookie limitation. 

When the 300 cookie limit or the 20 cookie per server limit is exceeded,
Navigator deletes the least recently used cookie. When a cookie larger
than 4 kilobytes is encountered the cookie should be trimmed to fit,
but the name should remain intact as long as it is less than 4 kilobytes.

TODO: encrypt and MAC

=cut

sub _init {
    my ($self, $args) = @_;
    my ($cgi, $sessiontext, $store, $length, $pad);

    my $context = $self->{context} = $args->{context};
    $store = {};
    $cgi = $args->{cgi} if (defined $args);
    if (! defined $cgi && $context->can("request")) {
        $cgi = $context->request()->{cgi};
    }
    if (defined $cgi) {
        $sessiontext = $cgi->cookie("app_sessiondata");
        if ($sessiontext) {
            my ($i, $textchunk);
            $i = 2;
            while (1) {
                $textchunk = $cgi->cookie("app_sessiondata${i}");
                last if (!$textchunk);
                $sessiontext .= $textchunk;
                $i++;
            }
            $sessiontext =~ s/ /\+/g;
            $length = length($sessiontext);
            $pad = 4 - ($length % 4);
            $pad = 0 if ($pad == 4);
            $sessiontext .= ("=" x $pad) if ($pad);
#print "length(sessiontext)=", length($sessiontext), "\n";
            $sessiontext =~ s/(.{76})/$1\n/g;
            $sessiontext .= "\n";
#print "Session::Cookie->_init(): sessiontext = [\n$sessiontext\n]\n";
            $store = thaw(Compress::Zlib::memGunzip(MIME::Base64::decode($sessiontext)));
        }
    }
    $self->{context} = $args->{context} if (defined $args->{context});
    $self->{store} = $store;
    $self->{cache} = {};
}

1;
