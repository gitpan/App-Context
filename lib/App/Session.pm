
#############################################################################
## $Id: Session.pm,v 1.6 2004/09/02 20:56:51 spadkins Exp $
#############################################################################

package App::Session;

use App;
use App::Reference;

use strict;

=head1 NAME

App::Session - represents a sequence of multiple events
perhaps executed in separate processes

=head1 SYNOPSIS

   # ... official way to get a Session object ...
   use App;
   $session = App->context();
   $context = $session->session();   # get the session

   # any of the following named parameters may be specified
   $session = $context->session(
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

This constructor is used to create Session objects.
Customized behavior for a particular type of Sessions
is achieved by overriding the _init() method.

    * Signature: $session = App::Session->new($array_ref)
    * Signature: $session = App::Session->new($hash_ref)
    * Signature: $session = App::Session->new("array",@args)
    * Signature: $session = App::Session->new(%named)
    * Param:     $array_ref          []
    * Param:     $hash_ref           {}
    * Return:    $session            App::Session
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage:

    use "App::Session";

    $ref = App::Session->new("array", "x", 1, -5.4, { pi => 3.1416 });
    $ref = App::Session->new( [ "x", 1, -5.4 ] );
    $ref = App::Session->new(
        arg1 => 'value1',
        arg2 => 'value2',
    );

=cut

sub new {
    &App::sub_entry if ($App::trace);
    my $this = shift;
    my $class = ref($this) || $this;

    my $self = {};
    bless $self, $class;

    $self->_init(@_);  # allows a subclass to override this portion

    &App::sub_exit($self) if ($App::trace);
    return $self;
}

=cut

#############################################################################
# _init()
#############################################################################

=head2 _init()

The _init() method is called from within the standard Session constructor.
The _init() method in this class does nothing.
It allows subclasses of the Session to customize the behavior of the
constructor by overriding the _init() method. 

    * Signature: _init($named)
    * Param:     $named        {}    [in]
    * Return:    void
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    $ref->_init($args);

=cut

sub _init {
    &App::sub_entry if ($App::trace);
    my $self = shift;
    &App::sub_exit() if ($App::trace);
}

#############################################################################
# PUBLIC METHODS
#############################################################################

=head1 Public Methods:

=cut

#############################################################################
# get()
#############################################################################

=head2 get()

The get() returns the var of a session_object.

    * Signature: $value = $session->get($service_name_var);
    * Signature: $value = $session->get($service, $name, $var);
    * Signature: $value = $session->get($service, $name, $var, $default);
    * Signature: $value = $session->get($service, $name, $var, $default, $setdefault);
    * Param:  $service        string
    * Param:  $name           string
    * Param:  $attribute      string
    * Param:  $default        any
    * Param:  $setdefault     boolean
    * Return: $value          string,ref
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    $cname = $session->get("cname");
    $cname = $session->get("default.cname");
    $cname = $session->get("SessionObject.default.cname");
    $cname = $session->get("SessionObject", "default", "cname");
    $width = $session->get("SessionObject", "main.app.toolbar.calc", "width", 45, 1);
    $width = $session->get("main.app.toolbar.calc.width",     undef,   undef, 45, 1);

=cut

sub get {
    &App::sub_entry if ($App::trace);
    my ($self, $service, $name, $var, $default, $setdefault) = @_;
    if (!defined $name) {
        if ($service =~ /^([A-Z][^.]*)\.(.+)/) {
            $service = $1;
            $name = $2;
        }
        else {
            $name = $service;
            $service = "SessionObject";
        }
        if ($name =~ /^([a-zA-Z0-9_\.-]+)([\{\}\[\]].*)$/) {
            $name = $1;
            $var = $2;
        }
        elsif ($name =~ /^([a-zA-Z0-9_\.-]+)\.([a-zA-Z0-9_]+)$/) {
            $name = $1;
            $var = $2;
        }
        else {
            $var  = $name;
            $name = "default";
        }
    }

    my ($perl, $value);

    if ($var !~ /[\[\]\{\}]/) {         # no special chars, "foo.bar"
        $value = $self->{cache}{$service}{$name}{$var};
        if (!defined $value && defined $default) {
            $value = $default;
            if ($setdefault) {
                $self->{store}{$service}{$name}{$var} = $value;
                $self->{context}->service($service, $name) if (!defined $self->{cache}{$service}{$name});
                $self->{cache}{$service}{$name}{$var} = $value;
            }
        }
        $self->dbgprint("Session->get($service,$name,$var) (value) = [$value]")
            if ($App::DEBUG && $self->dbg(3));
        return $value;
    } # match {
    elsif ($var =~ /^\{([^\}]+)\}$/) {  # a simple "{foo.bar}"
        $var = $1;
        $value = $self->{cache}{$service}{$name}{$var};
        if (!defined $value && defined $default) {
            $value = $default;
            if ($setdefault) {
                $self->{store}{$service}{$name}{$var} = $value;
                $self->{context}->service($service, $name) if (!defined $self->{cache}{$service}{$name});
                $self->{cache}{$service}{$name}{$var} = $value;
            }
        }
        $self->dbgprint("Session->get($service,$name,$var) (value) = [$value]")
            if ($App::DEBUG && $self->dbg(3));
        return $value;
    } # match {
    elsif ($var =~ /^[\{\}\[\]].*$/) {

        $self->{context}->service($service, $name) if (!defined $self->{cache}{$service}{$name});

        $var =~ s/\{([^\}]+)\}/\{"$1"\}/g;
        $perl = "\$value = \$self->{cache}{\$service}{\$name}$var;";
        eval $perl;
        $self->add_message("eval [$perl]: $@") if ($@);
        $self->dbgprint("Session->get($service,$name,$var) (indexed) = [$value]")
            if ($App::DEBUG && $self->dbg(3));
    }

    &App::sub_exit($value) if ($App::trace);
    return $value;
}

#############################################################################
# set()
#############################################################################

=head2 set()

The set() sets the value of a variable in one of the Services for the Session.

    * Signature: $session->set($service_name_var, $value);
    * Signature: $session->set($service, $name, $var, $value);
    * Param:  $service_name_var string
    * Param:  $service          string
    * Param:  $name             string
    * Param:  $var              string
    * Param:  $value            string,ref
    * Return: void
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    $session->set("cname",                             "main_screen");
    $session->set("default.cname",                     "main_screen");
    $session->set("SessionObject.default.cname",       "main_screen");
    $session->set("SessionObject", "default", "cname", "main_screen");
    $session->set("SessionObject", "main.app.toolbar.calc", "width", 50);
    $session->set("SessionObject", "xyz", "{arr}[1][2]",  14);
    $session->set("SessionObject", "xyz", "{arr.totals}", 14);

=cut

sub set {
    &App::sub_entry if ($App::trace);
    my ($self, $service, $name, $var, $value) = @_;
    if (!defined $value) {
        $value = $name;
        $name = undef;
    }
    if (!defined $name) {
        if ($service =~ /^([A-Z][^.]*)\.(.+)/) {
            $service = $1;
            $name = $2;
        }
        else {
            $name = $service;
            $service = "SessionObject";
        }
        if ($name =~ /^([a-zA-Z0-9_\.-]+)([\{\}\[\]].*)$/) {
            $name = $1;
            $var = $2;
        }
        elsif ($name =~ /^([a-zA-Z0-9_\.-]+)\.([a-zA-Z0-9_]+)$/) {
            $name = $1;
            $var = $2;
        }
        else {
            $var  = $name;
            $name = "default";
        }
    }

    if ($value eq "{:delete:}") {
        return $self->delete($service,$name,$var);
    }

    my ($perl);
    $self->dbgprint("Session->set($name,$var,$value)")
        if ($App::DEBUG && $self->dbg(3));

    if ($var !~ /[\[\]\{\}]/) {         # no special chars, "foo.bar"
        $self->{store}{$service}{$name}{$var} = $value;
        $self->{cache}{$service}{$name}{$var} = $value;
        return;
    } # match {
    elsif ($var =~ /^\{([^\}]+)\}$/) {  # a simple "{foo.bar}"
        $var = $1;
        $self->{store}{$service}{$name}{$var} = $value;
        $self->{cache}{$service}{$name}{$var} = $value;
        return;
    }
    elsif ($var =~ /^\{/) {  # i.e. "{columnSelected}{first_name}"

        $var =~ s/\{([^\}]+)\}/\{"$1"\}/g;  # put quotes around hash keys

        $perl  = "\$self->{store}{$service}{\$name}$var = \$value;";
        $perl .= "\$self->{cache}{$service}{\$name}$var = \$value;"
            if (defined $self->{cache}{$service}{$name});

        eval $perl;
        $self->add_message("eval [$perl]: $@") if ($@);
    }

    &App::sub_exit() if ($App::trace);
}

#############################################################################
# default()
#############################################################################

=head2 default()

The default() sets the value of a SessionObject's attribute
only if it is currently undefined.

    * Signature: $session->default($service_name_var, $value);
    * Signature: $session->default($service, $name, $var, $value);
    * Param:  $service_name_var string
    * Param:  $service          string
    * Param:  $name             string
    * Param:  $var              string
    * Param:  $value            string,ref
    * Return: $value            string,ref
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    $cname = $session->default("default", "cname");
    $width = $session->default("main.app.toolbar.calc", "width");

=cut

sub default {
    &App::sub_entry if ($App::trace);
    my ($self, $service, $name, $var, $value) = @_;
    $self->get($service, $name, $var, $value, 1);
    &App::sub_exit() if ($App::trace);
}

#############################################################################
# delete()
#############################################################################

=head2 delete()

The delete() deletes an attribute of a session_object in the Session.

    * Signature: $session->delete($service, $name, $attribute);
    * Param:  $service      string
    * Param:  $name         string
    * Param:  $attribute    string
    * Return: void
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    $session->delete("default", "cname");
    $session->delete("main.app.toolbar.calc", "width");
    $session->delete("xyz", "{arr}[1][2]");
    $session->delete("xyz", "{arr.totals}");

=cut

sub delete {
    &App::sub_entry if ($App::trace);
    my ($self, $service, $name, $var) = @_;
    if (!defined $name) {
        if ($service =~ /^([A-Z][^.]*)\.(.+)/) {
            $service = $1;
            $name = $2;
        }
        else {
            $name = $service;
            $service = "SessionObject";
        }
        if ($name =~ /^([a-zA-Z0-9_\.-]+)([\{\}\[\]].*)$/) {
            $name = $1;
            $var = $2;
        }
        elsif ($name =~ /^([a-zA-Z0-9_\.-]+)\.([a-zA-Z0-9_]+)$/) {
            $name = $1;
            $var = $2;
        }
        else {
            $var  = $name;
            $name = "default";
        }
    }

    my ($perl);

    $self->dbgprint("Session->delete($name,$var)")
        if ($App::DEBUG && $self->dbg(3));

    if (!defined $var || $var eq "") {
        if ($name =~ /^([a-zA-Z0-9_\.-]+)([\{\}\[\]].*)$/) {
            $name = $1;
            $var = $2;
        }
        elsif ($name =~ /^([a-zA-Z0-9_\.-]+)\.([a-zA-Z0-9_]+)$/) {
            $name = $1;
            $var = $2;
        }
        else {
            $var  = $name;
            $name = "default";
        }
    }

    if ($var !~ /[\[\]\{\}]/) {         # no special chars, "foo.bar"
        delete $self->{store}{$service}{$name}{$var};
        delete $self->{cache}{$service}{$name}{$var}
            if (defined $self->{cache}{$service}{$name});
        return;
    } # match {
    elsif ($var =~ /^\{([^\}]+)\}$/) {  # a simple "{foo.bar}"
        $var = $1;
        delete $self->{store}{$service}{$name}{$var};
        delete $self->{cache}{$service}{$name}{$var}
            if (defined $self->{cache}{$service}{$name});
        return;
    }
    elsif ($var =~ /^\{/) {  # { i.e. "{columnSelected}{first_name}"

        $var =~ s/\{([^\}]+)\}/\{"$1"\}/g;  # put quotes around hash keys

        $perl  = "delete \$self->{store}{$service}{\$name}$var;";
        $perl .= "delete \$self->{cache}{$service}{\$name}$var;"
            if (defined $self->{cache}{$service}{$name});

        eval $perl;
        $self->add_message("eval [$perl]: $@") if ($@);
        #die "ERROR: Session->delete($name,$var): eval ($perl): $@" if ($@);
    }
    # } else we do nothing with it!
    &App::sub_exit() if ($App::trace);
}

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

sub get_session_id {
    &App::sub_entry if ($App::trace);
    my $self = shift;
    my $session_id = $self->{session_id};
    if (!$session_id) {
        $session_id = $self->new_session_id();
        $self->{session_id} = $session_id;
    }
    &App::sub_exit($session_id) if ($App::trace);
    $session_id;
}

#############################################################################
# new_session_id()
#############################################################################

=head2 new_session_id()

The new_session_id() returns a new, unique session_id.

    * Signature: $session_id = $session->new_session_id();
    * Param:  void
    * Return: $session_id      string
    * Throws: <none>
    * Since:  0.01

    Sample Usage: 

    $session_id = $session->new_session_id();

=cut

my $seq = 0;

sub new_session_id {
    &App::sub_entry if ($App::trace);
    my $self = shift;
    my ($session_id);
    $seq++;
    $session_id = time() . ":" . $$;
    $session_id .= ":$seq" if ($seq > 1);
    &App::sub_exit($session_id) if ($App::trace);
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
    &App::sub_entry if ($App::trace);
    my ($self, $options) = @_;
    my ($session_id, $html);
    $session_id = $self->get_session_id();
    $html = "<input type=\"hidden\" name=\"app.session_id\" value=\"$session_id\">";
    &App::sub_exit($html) if ($App::trace);
    $html;
}

#############################################################################
# dump()
#############################################################################

=head2 dump()

    * Signature: $perl = $session->dump();
    * Param:     void
    * Return:    $perl      text
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    $session = $context->session();
    print $session->dump(), "\n";

=cut

use Data::Dumper;

sub dump {
    &App::sub_entry if ($App::trace);
    my ($self, $ref) = @_;
    $ref = $self if (!$ref);
    my %copy = %$ref;
    delete $copy{context};   # don't dump the reference to the context itself
    my $d = Data::Dumper->new([ \%copy ], [ "session" ]);
    $d->Indent(1);
    &App::sub_exit($d->Dump()) if ($App::trace);
    return $d->Dump();
}

sub print {
    my $self = shift;
    print $self->dump(@_);
}

1;

