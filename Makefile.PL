
######################################################################
## File: $Id: Makefile.PL 10841 2008-02-27 03:00:31Z spadkins $
######################################################################

use ExtUtils::MakeMaker;

my @programs = (
    "bin/app",
    #"bin/mason",
    "bin/call",
    "bin/app-apache",
    #"bin/app-netserver",
);

%opts = (
    'NAME'        => 'App-Context',
    'DISTNAME'    => 'App-Context',
    'VERSION'     => '0.966',
    'EXE_FILES'   => [ @programs ],
    'PREREQ_PM'   => {
        'App::Options'             => "0.01",  # for loading a startup configuration file
        'Compress::Zlib'           => "0.01",  # for compressed serialization and browser responses
        'Data::Dumper'             => "0.01",  # used for debugging
        'Date::Parse'              => "0.01",  # date support
        'Date::Format'             => "0.01",  # date support
        'Exception::Class'         => "0.01",  # allows exception hierarchies
        'Class::Data::Inheritable' => "0.01",  # [prereq for Exception::Class]
        'Devel::StackTrace'        => "0.01",  # [prereq for Exception::Class]
        'MIME::Base64'             => "2.1",   # used for turning binary (serialized?) data into text (Sessions)
        'Storable'                 => "0.01",  # used for serialization everywhere
    },
);

######################################################################
# MAKE THE MAKEFILE
######################################################################

WriteMakefile(%opts);

sub MY::postamble {
    return <<EOF;

install ::
	@\$(RM_F) "\$(PREFIX)/cgi-bin/app"
	@\$(CP) "\$(PREFIX)/bin/app" "\$(PREFIX)/cgi-bin/app"

EOF
}

