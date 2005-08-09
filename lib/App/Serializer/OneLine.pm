
#############################################################################
## $Id: OneLine.pm,v 1.2 2005/08/09 19:09:33 spadkins Exp $
#############################################################################

package App::Serializer::OneLine;

use App;
use App::Serializer;
@ISA = ( "App::Serializer" );

use strict;

=head1 NAME

App::Serializer::OneLine - Interface for serialization and deserialization

=head1 SYNOPSIS

    use App;

    $context = App->context();
    $serializer = $context->service("Serializer");  # or ...
    $serializer = $context->serializer();
    $data = {
        an => 'arbitrary',
        collection => [ 'of', 'data', ],
        of => {
            arbitrary => 'depth',
        },
    };
    $perl = $serializer->serialize($data);
    $data = $serializer->deserialize($perl);
    print $serializer->dump($data), "\n";

=head1 DESCRIPTION

A Serializer allows you to serialize a structure of data
of arbitrary depth to a scalar and deserialize it back to the
structure.

The OneLine serializer uses a simplified perl data structure syntax
as the serialized form of the data.  It is meant for parsing 
human-entered data and writing human-readable data.
(Sometimes, the one line does get pretty long.)

=cut

sub serialize {
    my ($self, $data) = @_;
    my ($perl);
    if (ref($data) eq "ARRAY") {
        $perl = $self->_serialize(",",",",@$data);
    }
    else {
        $perl = $self->_serialize(",",",",$data);
    }
    return $perl;
}

sub _serialize {
    my ($self, $evensep, $oddsep, @data) = @_;
    my $perl = "";
    $evensep = "," if (! defined $evensep);
    $oddsep = $evensep if (! defined $oddsep);
    my ($nelem, $elem);
    for ($nelem = 0; $nelem <= $#data; $nelem++) {
        if ($nelem % 2 == 1) {
            $perl .= $oddsep;
        }
        else {
            $perl .= $evensep if ($nelem);
        }
        $elem = $data[$nelem];
        if (! defined $elem) {
            $perl .= "undef";
        }
        elsif (ref($elem) eq "") {
            $perl .= $elem;
        }
        elsif (ref($elem) eq "ARRAY") {
            $elem = $self->_serialize(",", ",", @$elem);
            $perl .= "[$elem]";
        }
        elsif (ref($elem) eq "HASH") {
            $elem = $self->_serialize(",", "=", %$elem);
            $perl .= "{$elem}";
        }
        else {
            $perl .= $elem;
        }
    }
    return $perl;
}

sub deserialize {
    my ($self, $perl) = @_;
    my (@perl, $elem, @remove);
    # print "\$PERL=($perl)\n";
    $perl =~ s/,/\|/g if ($perl !~ /\|/);
    $perl =~ s/=>?/\|/g;
    @perl = split(/([\|\{\}\[\]])/, $perl);
    # print "\@PERL[split]=(", join("-",@perl), ")\n";
    for (my $i = $#perl; $i >= 0; $i--) {
        $elem = $perl[$i];
        $elem =~ s/^\s+//;   # trim leading whitespace
        $elem =~ s/\s+$//;   # trim trailing whitespace
        $perl[$i] = $elem;
        if ($elem eq "") {
            if ($i == 0) {
                if ($perl[$i+1] =~ /^[\{\[]$/) {  # match ]}
                    $remove[$i] = 1;
                }
            }
            elsif ($i < $#perl) {
                if (($perl[$i-1] !~ /^[\|\{\[]$/) ||   # match ]}
                    ($perl[$i-1] eq "|" && $perl[$i+1] =~ /^[\{\[]$/)) {  # match ]}
                    $remove[$i] = 1;
                }
            }
            else {  # match [{
                if ($perl[$i-1] =~ /^[\}\]]$/) { 
                    $remove[$i] = 1;
                }
            }
        }
    }
    if ($perl[$#perl] eq "|") {
        push(@perl, "");
    }
    for (my $i = $#perl; $i >= 0; $i--) {
        $elem = $perl[$i];
        if ($elem eq "|" || $remove[$i]) {
            splice(@perl, $i, 1);
        }
    }
    # print "\@PERL=(", join("-",@perl), ")\n";
    my @data = $self->_deserialize(\@perl, 0, $#perl);
    if ($#data > 0) {
        return(\@data);
    }
    elsif ($#data == 0 && !ref($data[0])) {
        return(\@data);
    }
    else {
        return($data[0]);
    }
}

sub _find_matchidx {
    my ($self, $perlparts, $idx) = @_;
    my ($matchidx, $depth);
    $depth = 0;
    for ($matchidx = $idx; $matchidx <= $#$perlparts; $matchidx++) {
        if ($perlparts->[$matchidx] eq "[" || $perlparts->[$matchidx] eq "{") {
            $depth++;
        }
        elsif ($perlparts->[$matchidx] eq "]" || $perlparts->[$matchidx] eq "}") {
            $depth--;
            last if ($depth == 0);
        }
    }
    return($matchidx);
}

sub _deserialize {
    my ($self, $perlparts, $startidx, $endidx) = @_;
    my (@data, $elem, @elems, $idx, $matchidx);
    $idx = $startidx;
    while ($idx <= $endidx) {
        if ($perlparts->[$idx] eq "[") {
            $matchidx = $self->_find_matchidx($perlparts, $idx);
            @elems = $self->_deserialize($perlparts, $idx+1, $matchidx-1);
            push(@data, [ @elems ]);
            $idx = $matchidx + 1;
        }
        elsif ($perlparts->[$idx] eq "{") {
            $matchidx = $self->_find_matchidx($perlparts, $idx);
            @elems = $self->_deserialize($perlparts, $idx+1, $matchidx-1);
            push(@elems, "") if ($#elems % 2 == 0);  # odd number not allowed
            push(@data, { @elems });
            $idx = $matchidx + 1;
        }
        else {
            $elem = $perlparts->[$idx];
            push(@data, ($elem eq "undef" ? undef : $elem));
            $idx++;
        }
    }
    return(@data);
}

sub serialized_content_type {
    'text/plain';
}

1;

