
#############################################################################
## $Id: SessionObject.pm,v 1.7 2005/08/09 19:05:02 spadkins Exp $
#############################################################################

package App::SessionObject;

use App;
use App::Service;
@ISA = ( "App::Service" );

use strict;

use Date::Parse;
use Date::Format;

=head1 NAME

App::SessionObject - Interface for configurable, stateful objects

=head1 SYNOPSIS

    use App;

    $context = App->context();
    $session_object = $context->service("SessionObject");  # or ...
    $session_object = $context->session_object();

=head1 DESCRIPTION

A SessionObject is an object that can be manipulated
without having to worry about its lifecycle (i.e. persistence,
saving and restoring state, etc.) or its location (local or remote).

=cut

#############################################################################
# CLASS GROUP
#############################################################################

=head1 Class Group: SessionObject

The following classes might be a part of the SessionObject Class Group.

=over

=item * Class: App::SessionObject

=item * Class: App::SessionObject::Entity
      - entity session_objects are business objects (like EJB)

=item * Class: App::SessionObject::Entity::Repository
      - a local entity session_object stored in a Repository

=item * Class: App::SessionObject::Entity::SOAP
      - a remote entity session_object, accessed via SOAP

=item * Class: App::SessionObject::HTML
      - user interface session_objects displayed on a browser in HTML

=item * Class: App::SessionObject::Curses
      - user interface session_objects displayed on a terminal using Curses

=item * Class: App::SessionObject::Gtk
      - user interface session_objects displayed in X11 using Gtk

=item * Class: App::SessionObject::Tk
      - user interface session_objects displayed in X11 using Tk

=item * Class: App::SessionObject::WxPerl
      - user interface session_objects displayed on Windows using wxPerl

=back

A SessionObject is an object that can be manipulated
without having to worry about its lifecycle (i.e. persistence,
saving and restoring state, etc.) or its location (local or remote).

A SessionObject is a App Service, and it inherits all of the features of
App Services.

  * Each SessionObject may be identified by a unique (text) name
  * Entity SessionObject are kept separate from UI SessionObject by naming convention
  * SessionObject are accessed by requesting them by name from the Context
  * SessionObject have attributes (which may be references to complex data structures)
  * Attributes of SessionObject are accessed via get()/set() methods
  * get($attribute) is equivalent to $self->{$attribute} (but not set())
  * Attributes may be defaulted in the code that first accesses the SessionObject,
    configured in the Config file, or overridden at runtime for the
    duration of the Session

A user interface SessionObject also has a display() method to display
the SessionObject on the user agent. 
The values that are set are stored in the user's Session, so
every user Session has a unique copy of every user interface
SessionObject.

An entity SessionObject is shared between all user Sessions.
It maintains its state in a shared data store such as a 
Repository.

=cut

#############################################################################
# CLASS
#############################################################################

=head1 Class: App::SessionObject

A SessionObject Service is a means by which an object can be manipulated
without having to worry about its lifecycle (i.e. persistence,
saving and restoring state, etc.) or its location (local or remote).

 * Throws: App::Exception::SessionObject
 * Since:  0.01

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
# _init()
#############################################################################

=head2 _init()

The _init() method is called from within the standard Service
constructor.
Common to all SessionObject initializations, is the absorption of container
attributes.  "Absorbable attributes" from the session_object are copied from
the container session_object to the initialized session_object.

    * Signature: _init($named)
    * Param:     $named      {}   [in]
    * Return:    void
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    $service->_init(\%args);

=cut

sub _init {
    &App::sub_entry if ($App::trace);
    my ($self, $args) = @_;
    my ($name, $absorbable_attribs, $container, $attrib);

    $name               = $self->{name};
    $absorbable_attribs = $self->absorbable_attribs();
    $container          = "default";
    if ($name =~ /^(.+)-[a-zA-Z][a-zA-Z0-9_]*$/) {
        $container = $1;
    }

    # absorb attributes of the container config if ...
    # TODO: sort out whether we need to absorb attributes more often
    #       (i.e. push model rather than a pull model)

    if ($absorbable_attribs) {    # ... there are known attributes to absorb

        # notice a recursion here on containers
        $container = $self->{context}->session_object($container);

        foreach $attrib (@$absorbable_attribs) {
            if (!defined $self->{$attrib}) {    # incorporate if not set yet
                $self->{$attrib} = $container->{$attrib};
            }
        }
    }
    &App::sub_exit() if ($App::trace);
}

#############################################################################
# PUBLIC METHODS
#############################################################################

#############################################################################
# Method: shutdown()
#############################################################################

=head2 shutdown()

    * Signature: $self->shutdown();
    * Throws:    App::Exception
    * Since:     0.01

    $session_object->shutdown();

=cut

sub shutdown {
    &App::sub_entry if ($App::trace);
    my ($self) = @_;
    &App::sub_exit() if ($App::trace);
}

=head1 Public Methods:

=cut

#############################################################################
# Method: container()
#############################################################################

=head2 container()

    * Signature: $self->container();
    * Signature: $self->container($name);
    * Params:    $name      string
    * Throws:    App::Exception
    * Since:     0.01

    $container = $session_object->container();

=cut

sub container {
    &App::sub_entry if ($App::trace);
    my ($self, $name) = @_;
    $name ||= $self->{name};
    my ($container);
    if ($name =~ /^(.+)-[a-zA-Z][a-zA-Z0-9_]*$/) {
        $container = $1;
    }
    else {
        $container = "default";
    }
    &App::sub_exit($container) if ($App::trace);
    return($container);
}

#############################################################################
# Method: container_attrib()
#############################################################################

=head2 container_attrib()

    * Signature: $attrib = $self->container_attrib();
    * Signature: $attrib = $self->container_attrib($name);
    * Params:    $name      string
    * Returns:   $attrib    string
    * Throws:    App::Exception
    * Since:     0.01

    $attrib = $session_object->container_attrib();

=cut

sub container_attrib {
    &App::sub_entry if ($App::trace);
    my ($self, $name) = @_;
    $name ||= $self->{name};
    my ($attrib);
    if ($name =~ /^.+-([a-zA-Z][a-zA-Z0-9_]*)$/) {
        $attrib = $1;
    }
    else {
        $attrib = $name;
    }
    &App::sub_exit($attrib) if ($App::trace);
    return($attrib);
}

#############################################################################
# Method: handle_event()
#############################################################################

=head2 handle_event()

    * Signature: $handled = $self->handle_event($session_object_name,$event,@args);
    * Param:     $session_object_name    string
    * Param:     $event          string
    * Param:     @args           any
    * Return:    $handled        boolean
    * Throws:    App::Exception
    * Since:     0.01

    $handled = $session_object->handle_event("app.table.sort","click","up",4,20);
    $handled = $session_object->handle_event("app.table","sort","down","last_name");

=cut

sub handle_event {
    &App::sub_entry if ($App::trace);
    my ($self, $wname, $event, @args) = @_;

    my $handled = 0;

    if ($event eq "noop") {   # handle all known events
        $handled = 1;
    }
    else {
        my $name = $self->{name};
        my $context = $self->{context};
        my $container = "default";
        if ($name =~ /^(.+)-[a-zA-Z][a-zA-Z0-9_]*$/) {
            $container = $1;
        }
        else {
            my $cname = $context->so_get("default","cname","default");
            if ($cname ne $name && $cname !~ /^$name\./) {
                $container = $cname;  # container is the current active widget
            }
        }
        if ($container eq "default") {
            $context->add_message("Event not handled: {$wname}.$event(@args)");
            $handled = 1;
        }
        else {
            my $w = $context->session_object($container);
            $handled = $w->handle_event($wname, $event, @args);  # bubble the event to container session_object
        }
    }

    &App::sub_exit($handled) if ($App::trace);
    return($handled);
}


#############################################################################
# Method: set_value()
#############################################################################

=head2 set_value()

    * Signature: $self->set_value($value);
    * Param:     $value          any
    * Return:    void
    * Throws:    App::Exception
    * Since:     0.01

    $session_object->set_value("hello");
    $session_object->set_value(43);

=cut

sub set_value {
    &App::sub_entry if ($App::trace);
    my ($self, $value) = @_;
    my $name = $self->{name};
    if ($name =~ /^(.+)\.([a-zA-Z][a-zA-Z0-9_]*)$/) {
        $self->{context}->so_set($1, $2, $value);
    }
    else {
        $self->{context}->so_set("default", $name, $value);
    }
    &App::sub_exit() if ($App::trace);
}

#############################################################################
# Method: get_value()
#############################################################################

=head2 get_value()

    * Signature: $value = $self->get_value();
    * Param:     void
    * Return:    $value          any
    * Throws:    App::Exception
    * Since:     0.01

    $value = $session_object->get_value();

=cut

sub get_value {
    &App::sub_entry if ($App::trace);
    my ($self, $default, $setdefault) = @_;
    my $value = $self->{context}->so_get($self->{name}, "", $default, $setdefault);
    &App::sub_exit($value) if ($App::trace);
    return $value;
}

#############################################################################
# Method: fget_value()
#############################################################################

=head2 fget_value()

    * Signature: $formatted_value = $self->fget_value();
    * Signature: $formatted_value = $self->fget_value($format);
    * Param:     $format            string
    * Return:    $formatted_value   scalar
    * Throws:    App::Exception
    * Since:     0.01

    $formatted_date = $date_session_object->fget_value();  # use default format
    $formatted_date = $date_session_object->fget_value("%Y-%m-%d"); # supply format

=cut

sub fget_value {
    &App::sub_entry if ($App::trace);
    my ($self, $format) = @_;
    $format = $self->get("format") if (!defined $format);
    my ($value);
    if (! defined $format) {
        $value = $self->get_value("");
    }
    else {
        my $type = $self->get("validate");
        $value = $self->get_value("");
        if ($type) {
            $value = App::SessionObject->format($value, $type, $format);
        }
    }
    &App::sub_exit($value) if ($App::trace);
    return($value);
}

#############################################################################
# Method: get_values()
#############################################################################

=head2 get_values()

    * Signature: $values = $self->get_values();
    * Signature: $values = $self->get_values($default);
    * Signature: $values = $self->get_values($default,$setdefault);
    * Param:     $default        any
    * Param:     $setdefault     boolean
    * Return:    $values         []
    * Throws:    App::Exception
    * Since:     0.01

    $values = $session_object->get_values();

=cut

sub get_values {
    &App::sub_entry if ($App::trace);
    my ($self, $default, $setdefault) = @_;
    my $values = $self->get_value($default, $setdefault);
    my (@values);
    if (!defined $values) {
        @values = ();
    }
    elsif (ref($values) eq "ARRAY") {
        @values = @$values;
    }
    else {
        @values = ($values);
    }
    &App::sub_exit(@values) if ($App::trace);
    return (@values);
}

#############################################################################
# Method: set()
#############################################################################

=head2 set()

    * Signature: $self->set($attribute,$value);
    * Param:     $attribute      string
    * Param:     $value          any
    * Return:    void
    * Throws:    App::Exception
    * Since:     0.01

    $session_object->set("last_name","Jones");

=cut

sub set {
    &App::sub_entry if ($App::trace);
    my ($self, $var, $value) = @_;
    $self->{context}->so_set($self->{name}, $var, $value);
    &App::sub_exit() if ($App::trace);
}

#############################################################################
# Method: get()
#############################################################################

=head2 get()

    * Signature: $value = $self->get($attribute);
    * Signature: $value = $self->get($attribute,$default);
    * Signature: $value = $self->get($attribute,$default,$setdefault);
    * Param:     $attribut       string
    * Param:     $default        any
    * Param:     $setdefault     boolean
    * Return:    $value          any
    * Throws:    App::Exception
    * Since:     0.01

    $last_name = $session_object->get("last_name");
    $is_adult = $session_object->get("adult_ind","Y");   # assume adult
    $is_adult = $session_object->get("adult_ind","Y",1); # assume adult, remember

=cut

sub get {
    &App::sub_entry if ($App::trace);
    my ($self, $var, $default, $setdefault) = @_;
    my $value = $self->{context}->so_get($self->{name}, $var, $default, $setdefault);
    &App::sub_exit($value) if ($App::trace);
    $value;
}

#############################################################################
# Method: delete()
#############################################################################

=head2 delete()

    * Signature: $self->delete($attribute);
    * Param:     $attribute      string
    * Return:    void
    * Throws:    App::Exception
    * Since:     0.01

    $session_object->delete("voter_id");

=cut

sub delete {
    &App::sub_entry if ($App::trace);
    my ($self, $var) = @_;
    my $result = $self->{context}->so_delete($self->{name}, $var);
    &App::sub_exit($result) if ($App::trace);
    $result;
}

#############################################################################
# Method: set_default()
#############################################################################

=head2 set_default()

    * Signature: $self->set_default($attribute,$default);
    * Param:     $attribute      string
    * Param:     $default        any
    * Return:    void
    * Throws:    App::Exception
    * Since:     0.01

    $session_object->set_default("adult_ind","Y");

=cut

sub set_default {
    &App::sub_entry if ($App::trace);
    my ($self, $var, $default) = @_;
    my $value = $self->{context}->so_get($self->{name}, $var, $default, 1);
    &App::sub_exit($value) if ($App::trace);
    $value;
}

#############################################################################
# Method: label()
#############################################################################

=head2 label()

    * Signature: $label = $self->label();
    * Signature: $label = $self->label($attrib);
    * Signature: $label = $self->label($attrib,$lang);
    * Param:     $session_object_name    string
    * Param:     $event          string
    * Param:     @args           any
    * Return:    $handled        boolean
    * Throws:    App::Exception
    * Since:     0.01

    print $w->label();           # "Allez!"  (if current lang is "fr")
    print $w->label("name");     # "Jacques" (translation of alternate attribute) (if curr lang is "fr")
    print $w->label("name","en");# "Jack"    (translation of alternate attribute) (override lang is "en")
    print $w->label("","en");    # "Go!"     (default label, overridden lang of "en")
    print $w->label("","en_ca"); # "Go! eh?" (default label, overridden lang of "en_ca")

=cut

sub label {
    &App::sub_entry if ($App::trace);
    my ($self, $attrib, $lang) = @_;
    my ($label);
    #print "label($attrib, $lang) [$self]\n";
    $attrib = "label" if (!$attrib && $self->{label});
    $attrib = "name"  if (!$attrib && $self->{name});
    $lang   = $self->{lang} if (!$lang);

    $label  = $self->{"${attrib}__${lang}"};
    return $label if (defined $label);

    $label = $self->{$attrib};
    $label = $self->translate($label,$lang) if ($lang);
    $self->{"${attrib}__${lang}"} = $label;      # cache it for later use
    #print "label($attrib, $lang) => $label\n";
    &App::sub_exit($label) if ($App::trace);
    return $label;
}

#############################################################################
# Method: values_labels()
#############################################################################

=head2 values_labels()

    * Signature: ($values, $labels) = $self->values_labels();
    * Param:     void
    * Return:    $values       []
    * Return:    $labels       {}
    * Throws:    App::Exception
    * Since:     0.01

    ($values, $labels) = $gender_session_object->values_labels();
    # $values = [ "M", "F" ];
    # $labels = { "M" => "Male", "F" => "Female" };

=cut

sub values_labels {
    &App::sub_entry if ($App::trace);
    my ($self) = @_;
    my ($domain, $values, $labels);

    $self->{context}->dbgprint("SessionObject->values_labels()")
        if ($App::DEBUG && $self->{context}->dbg(1));

    $domain = $self->get("domain");
    $values = $self->get("values");
    if (defined $values) {
        $labels = $self->labels();
    }
    elsif (defined $domain && $domain ne "") {

        $self->{context}->dbgprint("SessionObject->values_labels(): domain=$domain")
            if ($App::DEBUG && $self->{context}->dbg(1));

        ($values, $labels) = $self->{context}->value_domain($domain)->values_labels();
    }
    $values = [] if (! defined $values);
    $labels = {} if (! defined $labels);
    &App::sub_exit($values, $labels) if ($App::trace);
    ($values, $labels);
}

#############################################################################
# Method: labels()
#############################################################################

=head2 labels()

    * Signature: $labels = $self->labels();
    * Signature: $labels = $self->labels($attribute);
    * Signature: $labels = $self->labels($attribute,$lang);
    * Param:     $attribute      string
    * Param:     $lang           string
    * Return:    $labels         {}
    * Throws:    App::Exception
    * Since:     0.01

    $labels = $w->labels();
    $labels = $w->labels("names");
    $labels = $w->labels("","en");      # English
    $labels = $w->labels("","en_ca");   # Canadian English

=cut

sub labels {
    &App::sub_entry if ($App::trace);
    my ($self, $attrib, $lang) = @_;
    my ($labels, $langlabels, $key);
    $attrib = "labels" if (!defined $attrib || $attrib eq "");  #"labels" is the default attribute to translate
    $langlabels = $self->{"lang_${attrib}"};
    return $langlabels if (defined $langlabels);
    $labels = $self->get("labels");
    if (defined $lang && $lang ne "") {
        foreach $key (keys %$labels) {
            $langlabels->{$key} = $self->translate($labels->{$key},$lang);
        }
    }
    else {
        $lang = $self->get("lang");
        foreach $key (keys %$labels) {
            $langlabels->{$key} = $self->translate($labels->{$key},$lang);
        }
        $self->{"lang_${attrib}"} = $langlabels;      # cache it for later use
    }
    &App::sub_exit($langlabels) if ($App::trace);
    return $langlabels;
}

#############################################################################
# Method: dump()
#############################################################################

=head2 dump()

    * Signature: $text = $self->dump();
    * Param:     void
    * Return:    $text           text
    * Throws:    App::Exception
    * Since:     0.01

    $text = $session_object->dump();

=cut

use Data::Dumper;

sub dump {
    &App::sub_entry if ($App::trace);
    my $self = shift;
    my $d = Data::Dumper->new([ $self ], [ "session_object" ]);
    $d->Indent(1);
    $d->Dump();
    &App::sub_exit() if ($App::trace);
}

#############################################################################
# Method: print()
#############################################################################

=head2 print()

    * Signature: $self->print();
    * Param:     void
    * Return:    void
    * Throws:    App::Exception
    * Since:     0.01

    $w->print();

=cut

sub print {
    &App::sub_entry if ($App::trace);
    my $self = shift;
    print $self->dump();
    &App::sub_exit() if ($App::trace);
}

#############################################################################
# PUBLIC STATIC METHODS
#############################################################################

=head1 Public Static Methods:

=cut

#############################################################################
# Method: format()
#############################################################################

=head2 format()

    * Signature: $formatted_value = $self->format($value, $type, $format);
    * Param:     $value             scalar
    * Param:     $type              string
    * Param:     $format            string
    * Return:    $formatted_value   string
    * Throws:    App::Exception
    * Since:     0.01

    $formatted_value = $session_object->format("20020127","date","%Y-%m-%d");
    $formatted_value = $session_object->format("27-Jan-02","date","%Y-%m-%d");
    $formatted_value = $session_object->format("01/27/2002","date","%Y-%m-%d");
    $formatted_value = App::SessionObject->format("01/27/2002","date","%Y-%m-%d");

A static method.

=cut

sub format {
    my ($self, $value, $type, $format) = @_;
    return "" if (!defined $value || $value eq "");
    if ($type eq "date") {
        if ($value =~ /^([0-9]{4})([0-9]{2})([0-9]{2})$/) {
            $value = "$1-$2-$3";  # time2str doesn't get YYYYMMDD
        }
        return "" if ($value eq "0000-00-00");
        return time2str($format, str2time($value));
    }
}

#############################################################################
# Method: translate()
#############################################################################

=head2 translate()

    * Signature: $translated_label = $session_object->translate($label, $lang);
    * Param:     $label               string
    * Param:     $lang                string
    * Return:    $translated_label    string
    * Throws:    App::Exception
    * Since:     0.01

    $translated_label = $session_object->translate($label, $lang);
    print $w->translate("Hello","fr");     # "Bonjour"
    print $w->translate("Hello","fr_ca");  # "Bonjour, eh" (french canadian)

Translates the label into the desired language based on the dictionary
which is current in the session_object at the time.
This dictionary is usually a reference to a global dictionary
which is absorbed from the container session_object.

=cut

sub translate {
    my ($self, $label, $lang) = @_;

    #print "translate($label, $lang)\n";
    my $trans_label = $label || "";
    if (!$label) {
        # do nothing (reply with blank)
    }
    else {
        $lang = $self->{lang} if (!$lang);
        my $dict = $self->{dict};
        if (!$lang || !$dict) {
            # do nothing (return $label without translation)
        }
        else {
            $trans_label = $dict->{$lang}{$label};
            if (!defined $trans_label) {
                my $base_lang = $lang;
                $base_lang =~ s/_.*$//;   # trim the trailing modifier (en_us => en)
                $trans_label = $dict->{$base_lang}{$label} if ($base_lang ne $lang);
            }
            $trans_label = $dict->{default}{$label} if (!defined $trans_label);
            $trans_label = $label if (!$trans_label);
        }
    }

    return $trans_label;
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

Returns 'SessionObject';

    * Signature: $service_type = App::SessionObject->service_type();
    * Param:     void
    * Return:    $service_type  string
    * Since:     0.01

    $service_type = $session_object->service_type();

=cut

sub service_type () { 'SessionObject'; }

#############################################################################
# Method: absorbable_attribs()
#############################################################################

=head2 absorbable_attribs()

Returns a list of attributes which a service of this type would like to
absorb from its container service.
This is a *static* method.
It doesn't require an instance of the class to call it.

    * Signature: $attribs = App::Service->absorbable_attribs()
    * Param:     void
    * Return:    $attribs       []
    * Throws:    App::Exception
    * Since:     0.01

    $attribs = $session_object->absorbable_attribs();
    @attribs = @{$session_object->absorbable_attribs()};

=cut

sub absorbable_attribs {
    # for the general session_object, there are only a few universal absorbable attributes
    [ "lang", "dict" ];
}

=head1 ACKNOWLEDGEMENTS

 * Author:  Stephen Adkins <stephen.adkins@officevision.com>
 * License: This is free software. It is licensed under the same terms as Perl itself.

=head1 SEE ALSO

L<C<App::Context>|App::Context>,
L<C<App::Service>|App::Service>

=cut

1;

