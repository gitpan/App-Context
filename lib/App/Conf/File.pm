
#############################################################################
## $Id: File.pm,v 1.1 2002/09/09 01:34:10 spadkins Exp $
#############################################################################

package App::Conf::File;
$VERSION = do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r};

use App;
use App::Conf;
@ISA = ( "App::Conf" );

use strict;

sub create {
    my $self = shift;

    my ($args);
    if ($#_ >= 0 && ref($_[0]) eq "HASH") {
        $args = $_[0];
    }
    elsif ($#_ >= 0 && $#_ % 2 == 1) {
        $args = { @_ };
    }
    else {
        $args = {};
    }

    local(*FILE);
    my ($file, $nullfile, $testfile, $confdir, @files, $filebase, $filetype, $scriptbase, $script);
    my ($serializer_class, $open, $conf_found);

    $file = $args->{confFile};
    $nullfile = (!$file && exists $args->{confFile});

    # file not specified. try env variable.
    $file = $ENV{APP_CONF_FILE} if (!$file && !$nullfile);

    # $confdir and $scriptbase are common places for the file
    if ($args->{prefix}) {
        $confdir = $args->{prefix} . "/etc";
    }
    else {
        $confdir = $0;
        if ($confdir =~ m!/[^/]+$!) {
            $confdir =~ s!/[^/]+$!!;
        }
        else {
            $confdir = ".";
        }
        $confdir = "." if (!$confdir);
    }
    $scriptbase = $0;
    $scriptbase =~ s!.*/!!;        # remove leading path
    $script     = $scriptbase;
    $scriptbase =~ s!\.[^\.]+$!!;  # remove trailing extension (i.e. ".cgi")

    # now find the file on the file system
    $conf_found = 0;
    if ($file) {
        if (!$conf_found && -r $file) {
            $conf_found = 1;
        }
        if (!$conf_found && -r "etc/$file") {
            $file = "etc/$file";
            $conf_found = 1;
        }
        if (!$conf_found && -r "$confdir/$file") {
            $file = "$confdir/$file";
            $conf_found = 1;
        }
    }
    elsif (!$nullfile) {
        # no file specified, and we didn't explicitly declare that one did not exist
        # so we will look in common places with common names for a conf file
        if (!$file) {
            CONFFILE: foreach $filetype qw(pl xml ini properties perl conf) {
                foreach $filebase ($scriptbase, "app") {
                    $testfile = ($confdir eq ".") ? "$filebase.$filetype" : "$confdir/$filebase.$filetype";
                    next if ($testfile eq $script);
                    if (-r $testfile) {
                        $file = $testfile;
                        last CONFFILE;
                    }
                }
            }
        }
    }

    my (@text, $text, $conf, $key);

    $conf = {};

    if ($file) {
        $args->{confFile} = $file;

        # if a config file is specified, it must exist
        if (! open(main::FILE,"< $file")) {
            App::Exception::Conf->throw(
                error => "create(): [$file] $!\n"
            );
        }

        @text = <main::FILE>;
        close(main::FILE);
        $text = join("",@text);

        $serializer_class = $args->{confSerializerClass};
        $serializer_class = $ENV{APP_CONF_FILE_SERIALIZER} if (!$serializer_class);

        if (!$serializer_class) {

            $filetype = "";
            if ($file =~ /\.([^\.]+)$/) {
                $filetype = $1;
            }

            if ($filetype eq "pl") {
                $serializer_class = ""; # don't bother with a serializer
            }
            elsif ($filetype eq "perl") {
                $serializer_class = "App::Serializer::Dumper";
            }
            elsif ($filetype eq "stor") {
                $serializer_class = "App::Serializer::Storable";
            }
            elsif ($filetype eq "xml") {
                $serializer_class = "App::Serializer::XMLSimple";
            }
            elsif ($filetype eq "ini") {
                $serializer_class = "App::Serializer::Ini";
            }
            elsif ($filetype eq "properties") {
                $serializer_class = "App::Serializer::Properties";
            }
            elsif ($filetype eq "conf") {
                $serializer_class = "App::Serializer::Properties";
            }
            elsif ($filetype) {
                my $serializer = ucfirst($filetype);
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
                        error => "create(): [$file] error eval'ing config text: $@\n"
                    );
                }
            }
            else {
                App::Exception::Conf->throw(
                    error => "create(): [$file] config text doesn't match '\$var = {...};'\n"
                );
            }
        }
    }

    if ($args->{conf} && ref($args->{conf}) eq "HASH") {
        App::Reference->overlay($conf, $args->{conf});
    }

    $conf;
}

1;

