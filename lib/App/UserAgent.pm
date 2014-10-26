
#############################################################################
## $Id: UserAgent.pm,v 1.4 2004/09/02 20:56:51 spadkins Exp $
#############################################################################

package App::UserAgent;

use strict;

use App;

=head1 NAME

App::UserAgent - the browser this session is connected to

=head1 SYNOPSIS

   # ... official way to get a UserAgent object ...
   use App;
   $context = App->context();
   $user_agent = $context->user_agent();  # get the user_agent

   if ($user_agent->supports("html.input.style")) {
      # do something
   }

=cut

#############################################################################
# CONSTANTS
#############################################################################

=head1 DESCRIPTION

A UserAgent class models the browser connected to this session.
It is used to determine what capabilities are supported by the user agent.

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

The App::UserAgent->new() method is rarely called directly.
That is because a $user_agent should always be instantiated by getting
it from the $context [ $context->user_agent() ].

    * Signature: $user_agent = App::UserAgent->new($context);
    * Signature: $user_agent = App::UserAgent->new();
    * Param:  $context        App::Context
    * Return: $user_agent     App::UserAgent
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    [Common Use]
    $context = App->context();
    $user_agent = $context->user_agent();

    [Internal Use Only]
    $user_agent = App::UserAgent->new();

=cut

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless $self, $class;
    my ($context) = @_;

    $self->{context} = $context;
    if (defined $context) {
        $self->{http_user_agent} = $context->get_option("http_user_agent");
    }
    else {
        $self->{http_user_agent} =
            (defined $ENV{HTTP_USER_AGENT}) ?
            $ENV{HTTP_USER_AGENT} :
            "unknown";
    }

    my ($uatype, $uaver, $ostype, $osver, $arch, $ualang, $lang);

    ($uatype, $uaver, $ostype, $osver, $arch, $ualang) =
        $self->parse($self->{http_user_agent});

    if (defined $context) {
        $lang = $context->get_option("http_user_agent");
    }
    elsif (defined $ENV{HTTP_ACCEPT_LANGUAGE}) {
        $lang = lc($ENV{HTTP_ACCEPT_LANGUAGE});
        $lang =~ s/[ ,].*//;
    }

    $self->{uatype} = $uatype;
    $self->{uaver}  = $uaver;
    $self->{ostype} = $ostype;
    $self->{osver}  = $osver;
    $self->{arch}   = $arch;
    $self->{lang}   = $lang;

    $self->{supports} = $self->get_support_matrix($uatype, $uaver,
        $ostype, $osver, $arch, $lang);

    return $self;
}

#############################################################################
# PUBLIC METHODS
#############################################################################

=head1 Public Methods

=cut

#############################################################################
# supports()
#############################################################################

=head2 supports()

The supports() method returns whether or not a "feature" or "capability" is
supported by a user agent (browser).

    * Signature: $bool = $self->supports($capability);
    * Param:  $capability     string
    * Return: $bool           boolean
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    if ($ua->supports("html.input.style")) {
        # do something
    }

The following are some of the types of capabilities that the
browser may or may not support.
The capability categorization scheme is derived from the O'Reilly book,
"Dynamic HTML: The Definitive Reference", which has sections on HTML,
DOM, CSS, and JavaScript.  Java and HTTP capabilities are also
defined.
Finally, hints are defined which simply tell the session objects
what to use on certain browsers.

  html.<tag>
  html.<tag>.<attrib>
  html.input.style
  html.input.style.border-width

  dom
  dom.<object_class>
  dom.<object_class>.<attribute>

  style
  style.css1
  style.css2
  style.<attribute>

  js
  js.1.0
  js.1.1
  js.1.2
  js.<class>.<method>
  js.<class>.<attribute>

  java.1.0.0
  java.1.2.2
  java.1.3.0

  http.header.accept-encoding.x-gzip
  http.header.accept-encoding.x-compress

  session_object.Stylizable.style

=cut

sub supports {
    my ($self, $capability) = @_;

    # return immediately if support for the capability is already determined
    if (defined $self->{supports}{$capability}) {
        return ($self->{supports}{$capability});
    }

    if ($capability eq "http.header.accept-encoding.x-gzip") {
        my ($request, $accept_header, $support_status);
        $request = $self->{context}->request();
        $accept_header = $request->header("Accept-Encoding");
        $support_status = ($accept_header =~ /gzip/) ? 1 : 0;
        $self->{supports}{$capability} = $support_status;
        return $support_status;
    }

    # see if this capability has a "parent" capability
    if ($capability =~ /^(.*)\.([^\.]+)$/) {
        # we support it if we support its parent capability
        $self->{supports}{$capability} = $self->supports($1);
    }
    else {
        # assume we support everything unless otherwise informed
        $self->{supports}{$capability} = 1;
    }
    return $self->{supports}{$capability};
}

#############################################################################
# get()
#############################################################################

=head2 get()

The get() method retrieves attributes of the user agent.

    * Signature: $bool = $self->parse($http_user_agent);
    * Param:  $http_user_agent string
    * Return: $bool            boolean
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    $http_user_agent = "Mozilla/4.0 (compatible; MSIE 5.5; Windows NT)";
    @ua = $user_agent->parse($http_user_agent);
    @ua = $App::UserAgent->parse($ENV{HTTP_USER_AGENT});
    ($uatype, $uaver, $ostype, $osver, $arch, $lang) = @ua;

The following attributes of the $user_agent are also defined.
The bracketed values ([value]) are the defaults if no other value can
be determined by the HTTP_USER_AGENT string and the other HTTP headers.

  uatype - User Agent type       (i.e. [unknown], NS, IE, Opera, Konqueror, Mozilla)
  uaver  - User Agent version    (i.e. [1.0], 4.0, 4.7, 5.01) (always numeric)
  ostype - Oper System type      (i.e. [unknown], Windows, Macintosh, Linux, FreeBSD, HP-UX, SunOS, AIX, IRIX, OSF1)
  osver  - Oper System version   (i.e. [unknown], 16, 3.1, 95, 98, 2000, ME, NT 5.1)
  arch   - Hardware Architecture (i.e. [unknown], i386, i586, i686, ppc, sun4u, 9000/835)
  lang   - Preferred Language    (i.e. [en], en-us, fr-ca, ja, de)

There is very little reason for any SessionObject code to call get() directly.
SessionObjects should rather use the supports() method to determine whether a
capability is supported by the browser.  The supports method will
consult these attributes and its capability matrix to determine whether
the capability is supported or not.

sub get {
    my ($self, $attribute) = @_;
    $self->{$attribute};
}

#############################################################################
# parse()
#############################################################################

=head2 parse()

The parse() method parses an HTTP_USER_AGENT string and returns the
resulting attributes of the browser.

    * Signature: $bool = $self->parse($http_user_agent);
    * Param:  $http_user_agent string
    * Return: $bool            boolean
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    $http_user_agent = "Mozilla/4.0 (compatible; MSIE 5.5; Windows NT)";
    @ua = $user_agent->parse($http_user_agent);
    @ua = $App::UserAgent->parse($ENV{HTTP_USER_AGENT});
    ($uatype, $uaver, $ostype, $osver, $arch, $lang) = @ua;

Note: Two additional attributes, $mozver and $iever are probably going to
be needed.  They represent the Netscape/Mozilla version that the software
claims to operate like (IE has always included this) and the IE version
that the software claims to operate like (Opera includes this).
This will allow for a cascading of one type of compatibility matrix into
another.

=cut

sub parse {
    my ($self, $http_user_agent) = @_;
    my ($uatype, $uaver, $ostype, $osver, $arch, $lang);
    my ($ua);

    $uatype = "unknown"; # NS, IE, Opera, Konqueror, Mozilla, unknown
    $uaver  = 1.0;       # 4.0, 4.7, 5.01
    if ($http_user_agent =~ /MSIE[ \+\/]*([0-9][\.0-9]*)/) {
        $uatype = "IE";       # MS Internet Explorer
        $uaver = $1;
    }
    elsif ($http_user_agent =~ /Gecko[ \+\/]*([0-9][\.0-9]*)/) {
        $uatype = "Mozilla";  # from www.mozilla.org
        $uaver = $1;
    }
    # Opera should be first (unless we are OK to believe it is really MSIE)
    elsif ($http_user_agent =~ /Opera[ \+\/]*([0-9][\.0-9]*)/) {
        $uatype = "Opera";
        $uaver = $1;
    }
    elsif ($http_user_agent =~ /Konqueror[ \+\/]*([0-9][\.0-9]*)/) {
        $uatype = "Konqueror";
        $uaver = $1;
    }
    elsif ($http_user_agent =~ /Mozilla[ \+\/]*([0-9][\.0-9]*)/) {
        $uatype = "NS";       # the original Mozilla browser
        $uaver = $1;
    }

    # ostype/osver
    $ostype = "unknown"; # Windows, Macintosh, Linux, FreeBSD, HP-UX, SunOS
    $osver  = "unknown"; # 16, 3.1, 95, 98, 2000, ME, CE, NT 5.1
    $arch   = "unknown"; # i386, i586, i686, PPC
    $lang   = "en";      # en, en-US, ja, de

    $ua = $http_user_agent;
    $ua =~ s/\+/ /g;
    $ua =~ s/Service Pack /SP/g;
    if ($ua =~ /Win/) {
        if ($ua =~ /Win16/) {
            $ostype = "Windows";
            $osver = "16";
        }
        elsif ($ua =~ /Win32/) {
            $ostype = "Windows";
            $osver = "32";
        }
        elsif ($ua =~ /Win(9[58x])/) {
            $ostype = "Windows";
            $osver = $1;
        }
        elsif ($ua =~ /Win(NT *[SP0-9. ]*)/) {
            $ostype = "Windows";
            $osver = $1;
            $osver =~ s/ +$//;
        }
        elsif ($ua =~ /Windows *([239MCX][A-Z0-9. \/]*)/) {
            $ostype = "Windows";
            $osver = $1;
            $osver =~ s/ +$//;
        }
    }
    if ($ostype eq "unknown") {   # haven't found it yet
        if ($ua =~ /Linux/) {
            $ostype = "Linux";
            if ($ua =~ /Linux +([0-9][0-9\.a-z-]*) +([a-zA-Z0-9-]+)/) {
                $osver = $1;
                $arch = $2;
            }
            elsif ($ua =~ /Linux +([0-9][0-9\.a-z-]*)/) {
                $osver = $1;
            }
        }
        elsif ($ua =~ /X11/) {
            $ostype = "X11";
        }
    }

    # arch
    if ($http_user_agent =~ /MSIE[ \+]?([0-9][\.0-9]*)/) {
        $uatype = "IE";
        $uaver = $1;
    }

    # lang
    if ($http_user_agent =~ /\[([a-zA-Z]{2})\]/) {
        $lang = $1;
    }
    elsif ($http_user_agent =~ /\[([a-zA-Z]{2}[-_][a-zA-Z]{2})\]/) {
        $lang = $1;
    }

    return ($uatype, $uaver, $ostype, $osver, $arch, $lang);
}

#############################################################################
# PROTECTED METHODS
#############################################################################

=head1 Protected Methods

=cut

#############################################################################
# get_support_matrix()
#############################################################################

=head2 get_support_matrix()

The get_support_matrix() method returns whether or not a "feature" or "capability" is
supported by a user agent (browser).

    * Signature: $support_matrix = $ua->get_support_matrix($uatype, $uaver, $ostype, $osver, $arch, $lang);
    * Param:  $uatype         string
    * Param:  $uaver          float
    * Param:  $ostype         string
    * Param:  $osver          string
    * Param:  $arch           string
    * Param:  $lang           string
    * Return: $support_matrix {}
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    $support_matrix = $self->get_support_matrix($uatype, $uaver, $ostype, $osver, $arch, $lang);

The following are some of the types of capabilities that the
browser may or may not support.

=cut

sub get_support_matrix {
    my ($self, $uatype, $uaver, $ostype, $osver, $arch, $lang) = @_;
    my ($support_matrix);

    # eventually, this will probably attach to an external DBM-style
    # capabilities database.  But for now, we just need a few features.
    $support_matrix = {};

    if ($uatype eq "NS" && $uaver <= 4.7) {
        $support_matrix->{"session_object.Stylizable.style"} = 0;
    }
    else {
        $support_matrix->{"session_object.Stylizable.style"} = 1;
    }

    return $support_matrix;
}

1;

