
#############################################################################
## $Id: File.pm,v 1.7 2004/02/27 14:21:21 spadkins Exp $
#############################################################################

package App::Conf::File;
$VERSION = do { my @r=(q$Revision: 1.7 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r};

use App;
use App::Conf;
@ISA = ( "App::Conf" );

use strict;

sub create {
    my $self = shift;

    my ($options);
    if ($#_ >= 0 && ref($_[0]) eq "HASH") {
        $options = $_[0];
    }
    elsif ($#_ >= 0 && $#_ % 2 == 1) {
        $options = { @_ };
    }
    else {
        $options = {};
    }

    my @conf_file = ();
    my ($app, $conf_type, $conf_file);
    $conf_file = $options->{conf_file};
    if (defined $conf_file) {
        if ($conf_file) {
            @conf_file = ( $conf_file );
            $conf_type = "pl";
            if ($conf_file =~ /\.([^\.]+)$/) {
                $conf_type = $1;
            }
            # if a config file is specified, it must exist
            if (! -r $conf_file) {
                App::Exception::Conf->throw(
                    error => "create(): [$conf_file] $!\n"
                );
            }
        }
    }
    else {
        #################################################################
        # 3. find the directory the program was run from
        #    we will use this directory to search for the
        #    initialization configuration file.
        #################################################################
        my $prog_dir = $0;                   # start with the full script path
        if ($prog_dir =~ m!^/!) {            # absolute path
            # i.e. /usr/local/bin/app, /app
            $prog_dir =~ s!/[^/]+$!!;        # trim off the program name
        }
        else {                               # relative path
            # i.e. app, ./app, ../bin/app, bin/app
            $prog_dir =~ s!/?[^/]+$!!;       # trim off the program name
            $prog_dir = "." if (!$prog_dir); # if nothing left, directory is current dir
        }

        #################################################################
        # 4. find the base "prefix" directory for the entire
        #    software installation.
        #################################################################
        my $prefix = $options->{prefix};

        #################################################################
        # 5. Define the standard places to look for a conf file
        #################################################################
        $app = $options->{app} || "app";
        $conf_type = $options->{conf_type} || "pl";
        push(@conf_file, "$ENV{HOME}/.app/$app.$conf_type") if ($ENV{HOME} && $app ne "app");
        push(@conf_file, "$ENV{HOME}/.app/app.$conf_type") if ($ENV{HOME});
        push(@conf_file, "$prog_dir/$app.$conf_type") if ($app ne "app");
        push(@conf_file, "$prog_dir/app.$conf_type");
        push(@conf_file, "$prefix/etc/app/$app.$conf_type") if ($app ne "app");
        push(@conf_file, "$prefix/etc/app/app.$conf_type");
    }

    #################################################################
    # 6. now actually read in the file
    #################################################################

    local(*FILE);
    my (@text, $text, $serializer_class);
    my $conf = {};
    while ($#conf_file > -1) {
        $conf_file = shift(@conf_file);
        print STDERR "Looking for conf_file [$conf_file]\n" if ($options->{debug_conf});
        if (open(App::FILE, "< $conf_file")) {
            print STDERR "Found conf_file [$conf_file]\n" if ($options->{debug_conf});
            @conf_file = ();      # don't look any farther
            @text = <App::FILE>;
            close(App::FILE);
            $text = join("",@text);
            #$text =~ /^(.*)/s;
            #$text = $1;

            # Now do substitutions for {:var:} or {:var=default:} in the config file to the value in the options file
            # (we really should do this only for text file types)
            $text =~ s/\{:([a-zA-Z0-9_]+)(=?)([^:\{\}]*):\}/(defined $options->{$1} ? $options->{$1} : ($2 ? $3 : $1))/eg;

            $serializer_class = $options->{conf_serializer_class};

            if (!$serializer_class) {
                if ($conf_type eq "pl") {
                    $serializer_class = ""; # don't bother with a serializer
                }
                elsif ($conf_type eq "perl") {
                    $serializer_class = "App::Serializer::Perl";
                }
                elsif ($conf_type eq "stor") {
                    $serializer_class = "App::Serializer::Storable";
                }
                elsif ($conf_type eq "xml") {
                    $serializer_class = "App::Serializer::Xml";
                }
                elsif ($conf_type eq "ini") {
                    $serializer_class = "App::Serializer::Ini";
                }
                elsif ($conf_type eq "properties") {
                    $serializer_class = "App::Serializer::Properties";
                }
                elsif ($conf_type eq "conf") {
                    $serializer_class = "App::Serializer::Properties";
                }
                elsif ($conf_type eq "yaml") {
                    $serializer_class = "App::Serializer::Yaml";
                }
                elsif ($conf_type) {
                    my $serializer = ucfirst($conf_type);
                    $serializer_class = "App::Serializer::$serializer";
                }
                else {
                    $serializer_class = "App::Serializer";
                }
            }

            if ($serializer_class) {
                eval "use $serializer_class;";
                if ($@) {
                    App::Exception::Conf->throw(
                        error => "create(): error loading $serializer_class serializer class: $@\n"
                    );
                }
                $conf = $serializer_class->deserialize($text);
                if (! %$conf) {
                    App::Exception::Conf->throw(
                        error => "create(): $serializer_class produced empty config\n"
                    );
                }
            }
            else { # don't bother with a serializer
                $conf = {};
                if ($text =~ /^[ \t\n]*\$[a-zA-Z][a-zA-Z0-9_]* *= *(\{.*\};[ \n]*)$/s) {
                    $text = "\$conf = $1";   # untainted now
                    eval($text);
                    if ($@) {
                        App::Exception::Conf->throw(
                            error => "create(): [$conf_file] error eval'ing config text: $@\n"
                        );
                    }
                }
                else {
                    App::Exception::Conf->throw(
                        error => "create(): [$conf_file] config text doesn't match '\$var = {...};'\n"
                    );
                }
            }
        }
    }
    
    if ($options->{conf} && ref($options->{conf}) eq "HASH") {
        App::Reference->overlay($conf, $options->{conf});
    }

    $conf;
}

1;

