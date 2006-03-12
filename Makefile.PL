
######################################################################
## File: $Id: Makefile.PL 3553 2006-03-01 03:30:20Z spadkins $
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
    'VERSION'     => '0.962',
    'EXE_FILES'   => [ @programs ],
    'PREREQ_PM'   => {
        'App::Options'             => 0,     # for loading a startup configuration file
        'Compress::Zlib'           => 0,     # for compressed serialization and browser responses
        'Data::Dumper'             => 0,     # used for debugging
        'Date::Parse'              => 0,     # date support
        'Date::Format'             => 0,     # date support
        'Exception::Class'         => 0,     # allows exception hierarchies
        'Class::Data::Inheritable' => 0,     # [prereq for Exception::Class]
        'Devel::StackTrace'        => 0,     # [prereq for Exception::Class]
        'MIME::Base64'             => "2.1", # used for turning binary (serialized?) data into text (Sessions)
        'Storable'                 => 0,     # used for serialization everywhere
    },
);

######################################################################
# MAKE THE MAKEFILE
######################################################################

WriteMakefile(%opts);

sub MY::postamble {
    return <<EOF;

install ::
	@\$(MOD_INSTALL) cgi-bin "\$(PREFIX)/cgi-bin"

EOF
}

