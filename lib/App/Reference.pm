
#############################################################################
## $Id: Reference.pm,v 1.4 2005/01/07 13:08:02 spadkins Exp $
#############################################################################

package App::Reference;
$VERSION = do { my @r=(q$Revision: 1.4 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r};

use strict;

use App;

=head1 NAME

App::Reference - a Perl reference, blessed so it can be accessed with methods

=head1 SYNOPSIS

   use App::Reference;

   $ref = App::Reference->new();
   $ref = App::Reference->new("file" => $file);
   print $ref->dump(), "\n";   # use Data::Dumper to spit out the Perl representation

   # accessors
   $property_value = $ref->get($property_name);
   $branch = $ref->get_branch($branch_name,$create_flag);  # get hashref
   $ref->set($property_name, $property_value);

   # on-demand loading helper methods (private methods)
   $ref->overlay($ref2);        # merge the two structures using overlay rules
   $ref->overlay($ref1, $ref2);  # merge $ref2 onto $ref1
   $ref->graft($branch_name, $ref2);  # graft new structure onto branch

=head1 DESCRIPTION

App::Reference is a very thin class which wraps a few simple
methods around a perl reference which may contain a multi-level data
structure.

=cut

#############################################################################
# CLASS
#############################################################################

=head1 Class: App::Reference

    * Throws: App::Exception
    * Since:  0.01

=head2 Requirements

The App::Reference class satisfies the following requirements.

    o Minimum performance penalty to access perl data
    o Ability to bless any reference into this class
    o Ability to handle ARRAY and HASH references

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

This constructor is used to create Reference objects.
Customized behavior for a particular type of Reference
is achieved by overriding the _init() method.

    * Signature: $ref = App::Reference->new($array_ref)
    * Signature: $ref = App::Reference->new($hash_ref)
    * Signature: $ref = App::Reference->new("array",@args)
    * Signature: $ref = App::Reference->new(%named)
    * Param:     $array_ref          []
    * Param:     $hash_ref           {}
    * Return:    $ref                App::Reference
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage:

    use "App::Reference";

    $ref = App::Reference->new("array", "x", 1, -5.4, { pi => 3.1416 });
    $ref = App::Reference->new( [ "x", 1, -5.4 ] );
    $ref = App::Reference->new(
        arg1 => 'value1',
        arg2 => 'value2',
    );

=cut

sub new {
    my $this = shift;
    my $class = ref($this) || $this;

    # bootstrap phase: bless an empty hash
    my $self = {};
    bless $self, $class;

    # create phase: replace empty hash with created hash, bless again
    $self = $self->create(@_);
    bless $self, $class;

    $self->_init(@_);  # allows a subclass to override this portion

    return $self;
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

    * Signature: $property_value = $ref->get($property_name);
    * Param:     $property_name    string
    * Return:    $property_value   string
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    $dbi    = $ref->get("Repository.default.dbi");
    $dbuser = $ref->get("Repository.default.dbuser");
    $dbpass = $ref->get("Repository.default.dbpass");

=cut

sub get {
    print "get(@_)\n" if ($App::DEBUG);
    my ($self, $property_name, $ref) = @_;
    $ref = $self if (!defined $ref);
    if ($property_name =~ /^(.*)([\.\{\[])([^\.\[\]\{\}]+)([\]\}]?)$/) {
        my ($branch_name, $attrib, $type, $branch);
        $branch_name = $1;
        $type = $2;
        $attrib = $3;
        $branch = ref($ref) eq "ARRAY" ? undef : $ref->{_branch}{$branch_name};
        $branch = $self->get_branch($1,0,$ref) if (!defined $branch);
        return undef if (!defined $branch || ref($branch) eq "");
        return $branch->[$attrib] if (ref($branch) eq "ARRAY");
        return $branch->{$attrib};
    }
    else {
        return $self->{$property_name};
    }
}

#############################################################################
# get_branch()
#############################################################################

=head2 get_branch()

    * Signature: $branch = $ref->get_branch($branch_name);
    * Param:     $branch_name  string
    * Return:    $branch       {}
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    $branch_name = "Repository.default";
    $branch = $ref->get_branch($branch_name);
    foreach $key (keys %$branch) {
        $property = "${branch_name}.${key}";
        print $property, "=", $branch->{$key}, "\n";
    }
    $dbi    = $branch->{dbi};
    $dbuser = $branch->{dbuser};
    $dbpass = $branch->{dbpass};

=cut

sub get_branch {
    print "get_branch(@_)\n" if ($App::DEBUG);
    my ($self, $branch_name, $create, $ref) = @_;
    my ($sub_branch_name, $branch_piece, $attrib, $type, $branch, $cache_ok);
    $ref = $self if (!defined $ref);

    # check the cache quickly and return the branch if found
    $cache_ok = (ref($ref) ne "ARRAY" && $ref eq $self); # only cache from $self
    $branch = $ref->{_branch}{$branch_name} if ($cache_ok);
    return ($branch) if (defined $branch);

    # not found, so we need to parse the $branch_name and walk the $ref tree
    $branch = $ref;
    $sub_branch_name = "";

    # these: "{field1}" "[3]" "field2." are all valid branch pieces
    while ($branch_name =~ s/^([\{\[]?)([^\.\[\]\{\}]+)([\.\]\}]?)//) {

        $branch_piece = $2;
        $type = $3;
        $sub_branch_name .= ($3 eq ".") ? "$1$2" : "$1$2$3";

        if (ref($branch) eq "ARRAY") {
            if (! defined $branch->[$branch_piece]) {
                if ($create) {
                    $branch->[$branch_piece] = ($type eq "]") ? [] : {};
                    $branch = $branch->[$branch_piece];
                    $ref->{_branch}{$sub_branch_name} = $branch if ($cache_ok);
                }
                else {
                    return(undef);
                }
            }
            else {
                $branch = $branch->[$branch_piece];
                $sub_branch_name .= "$1$2$3";   # accumulate the $sub_branch_name
            }
        }
        else {
            if (! defined $branch->{$branch_piece}) {
                if ($create) {
                    $branch->{$branch_piece} = ($type eq "]") ? [] : {};
                    $branch = $branch->{$branch_piece};
                    $ref->{_branch}{$sub_branch_name} = $branch if ($cache_ok);
                }
                else {
                    return(undef);
                }
            }
            else {
                $branch = $branch->{$branch_piece};
            }
        }
        $sub_branch_name .= $type if ($type eq ".");
    }
    return $branch;
}

#############################################################################
# set()
#############################################################################

=head2 set()

    * Signature: $ref->get($property_name, $property_value);
    * Param:     $property_name    string
    * Param:     $property_value   string
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    $dbi    = $ref->get("Repository.default.dbi");
    $dbuser = $ref->get("Repository{default}{dbuser}");
    $dbpass = $ref->get("Repository.default{dbpass}");

=cut

sub set {
    print "set(@_)\n" if ($App::DEBUG);
    my ($self, $property_name, $property_value, $ref) = @_;
    $ref = $self if (!defined $ref);

    my ($branch_name, $attrib, $type, $branch, $cache_ok);
    if ($property_name =~ /^(.*)([\.\{\[])([^\.\[\]\{\}]+)([\]\}]?)$/) {
        $branch_name = $1;
        $type = $2;
        $attrib = $3;
        $cache_ok = (ref($ref) ne "ARRAY" && $ref eq $self);
        $branch = $ref->{_branch}{$branch_name} if ($cache_ok);
        $branch = $self->get_branch($1,1,$ref) if (!defined $branch);
    }
    else {
        $branch = $ref;
        $attrib = $property_name;
    }

    if (ref($branch) eq "ARRAY") {
        $branch->[$attrib] = $property_value;
    }
    else {
        $branch->{$attrib} = $property_value;
    }
}

#############################################################################
# overlay()
#############################################################################

=head2 overlay()

    * Signature: $ref->overlay($ref2);
    * Signature: $ref->overlay($ref1, $ref2);
    * Param:     $ref1      {}
    * Param:     $ref2      {}
    * Return:    void
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    # merge the two config structures using overlay rules
    $ref->overlay($ref2);

    # merge $ref2 onto $ref1
    $ref->overlay($ref1, $ref2);

NOTE: right now, this just copies top-level keys of a hash reference
from one hash to the other.

TODO: needs to nested/recursive overlaying

=cut

sub overlay {
    &App::sub_entry if ($App::trace);
    my $self = shift;
    my ($ref1, $ref2, $key);
    return if ($#_ < 0 || $#_ > 1);
    if ($#_ == 0) {
        $ref1 = $self;
        $ref2 = $_[0];
    }
    else {
        $ref1 = $_[0];
        $ref2 = $_[1];
    }
    my $ref1type = ref($ref1);
    my $ref2type = ref($ref2);
    if ($ref1type eq "ARRAY" && $ref1type eq $ref2type) {
        # array: nothing to do
    }
    elsif ($ref1type eq "" && $ref1type eq $ref2type) {
        # scalar: nothing to do
    }
    else {
        # hash
        foreach $key (keys %$ref2) {
            if (!exists $ref1->{$key}) {
                $ref1->{$key} = $ref2->{$key};
            }
            else {
                $ref1type = ref($ref1->{$key});
                if ($ref1type && $ref1type ne "ARRAY") {
                    $ref2type = ref($ref2->{$key});
                    if ($ref1type eq $ref2type) {
                        $self->overlay($ref1->{$key}, $ref2->{$key});
                    }
                }
            }
        }
    }
    &App::sub_exit() if ($App::trace);
}

#############################################################################
# graft()
#############################################################################

=head2 graft()

    * Signature: $ref->graft($branch_name, $ref2);
    * Param:     $branch_name   string
    * Param:     $ref2       {}
    * Return:    void
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    # graft new config structure onto branch
    $ref->graft($branch_name, $ref2);

=cut

sub graft {
}

#############################################################################
# dump()
#############################################################################

=head2 dump()

    * Signature: $perl = $ref->dump();
    * Param:     void
    * Return:    $perl      text
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    $ref = $context->config();
    print $ref->dump(), "\n";

=cut

use Data::Dumper;

sub dump {
    my ($self, $ref) = @_;
    $ref = $self if (!$ref);
    my $d = Data::Dumper->new([ $ref ], [ "ref" ]);
    $d->Indent(1);
    return $d->Dump();
}

#############################################################################
# print()
#############################################################################

=head2 print()

    * Signature: $ref->print();
    * Param:     void
    * Return:    void
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    $context->print();

=cut

sub print {
    my ($self, $ref) = @_;
    $ref = $self if (!$ref);
    print $self->dump($ref);
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
It may be overridden by a subclass to provide customized behavior.

    * Signature: $ref = App::Reference->create("array", @args)
    * Signature: $ref = App::Reference->create($arrayref)
    * Signature: $ref = App::Reference->create($hashref)
    * Signature: $ref = App::Reference->create($hashref, %named)
    * Signature: $ref = App::Reference->create(%named)
    * Param:     $hashref            {}
    * Param:     $arrayref           []
    * Return:    $ref                ref
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage:

=cut

sub create {
    my $self = shift;
    print "create(@_)\n" if ($App::DEBUG);
    return {} if ($#_ == -1);
    if (ref($_[0]) ne "") {
        return $_[0] if ($#_ == 0);
        App::Exception->throw(error => "Reference->create(): args supplied with an ARRAY ref\n")
            if (ref($_[0]) eq "ARRAY");
        my ($ref, $i);
        $ref = shift;
        for ($i = 0; $i < $#_; $i += 2) {
            #print "arg: $_[$i] => $_[$i+1]\n";
            $ref->{$_[$i]} = $_[$i+1];
        }
        return $ref;
    }
    if ($_[0] eq "array") {
        shift;
        return [ @_ ];
    }
    elsif ($#_ % 2 == 0) {
        App::Exception->throw(error => "Reference->create(): Odd number of named parameters\n");
    }
    return { @_ };
}

#############################################################################
# _init()
#############################################################################

=head2 _init()

The _init() method is called from within the standard Reference constructor.
The _init() method in this class does nothing.
It allows subclasses of the Reference to customize the behavior of the
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
    my $self = shift;
}

#############################################################################
# PRIVATE METHODS
#############################################################################

=head1 Private Methods:

The following methods are intended to be called only within this class.

=cut

=head1 ACKNOWLEDGEMENTS

    * Author:  Stephen Adkins <stephen.adkins@officevision.com>
    * License: This is free software. It is licensed under the same terms as Perl itself.

=head1 SEE ALSO

none

=cut

1;

