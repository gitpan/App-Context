
######################################################################
## File: $Id: Makefile.PL,v 1.1 2002/09/09 01:34:10 spadkins Exp $
######################################################################

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# * The files in "sbin" are used during installation but are not
# installed themselves.  Executables that are also to be installed
# should be in "bin".
# * I borrowed the technique for putting the correct interpreter line
# at the top of scripts from the libwww-perl distribution.

my @bin_programs  = qw(app);
my @sbin_programs = qw(perldocs);
my @cgibin_programs = qw(p5x ttx button);

%opts = (
    #'INSTALLDIRS' => 'perl',
    'NAME'        => 'App-Context',
    'DISTNAME'    => 'App-Context',
    'VERSION'     => '0.01',
    #'PL_FILES'    => { (map {("sbin/$_.PL" => "sbin/$_")} @sbin_programs),
    #                   (map {("cgi-bin/$_.PL" => "cgi-bin/$_")} @cgibin_programs),
    #                   (map {("bin/$_.PL" => "bin/$_")} @bin_programs )},
    #'EXE_FILES'   => [ (map {"bin/$_"} @bin_programs) ],
    'PREREQ_PM'   => { # I haven't yet determined what the minimum versions should be
                       #'Aspect'                   => 0,  # used for debugging
                       #'Class::MethodMaker'       => 0,  # [prereq for Aspect] auto-generate methods
                       'Compress::Zlib'           => 0,  # for compressed serialization and browser responses
                       'Data::Dumper'             => 0,  # used for debugging
                       'Date::Parse'              => 0,  # date support
                       'Date::Format'             => 0,  # date support
                       #'Error'                    => 0,  # allows try/catch syntax for exceptions (deprecated)
                       'Exception::Class'         => 0,  # allows exception hierarchies
                       'Class::Data::Inheritable' => 0,  # [prereq for Exception::Class]
                       'Devel::StackTrace'        => 0,  # [prereq for Exception::Class]
                       #'Fatal'                    => 0,  # causes perl functions to throw exceptions
                       #'Hook::LexWrap'            => 0,  # [prereq for Aspect] support PRE/POST processing for subs
                       'MIME::Base64'             => "2.1", # used for turning binary (serialized?) data into text (Sessions)
                       'Storable'                 => 0,  # used for serialization everywhere
                     },
    #'clean'       => { FILES => '$(EXE_FILES)' },
    'linkext'     => { LINKTYPE=>'' },   # no link needed
    'dist'        => {'COMPRESS'=>'gzip -9f', 'SUFFIX' => 'gz',
                      'ZIP'=>'/usr/bin/zip','ZIPFLAGS'=>'-rl'},
);

######################################################################
# PREFIX
######################################################################

# I like setting the PREFIX variable in the environment,
# so I write my Makefile.PL to use it as a valid alternative
# to specifying it on the command line with
# "perl Makefile.PL PREFIX=/usr/foo".

if ($ENV{PREFIX}) {
    $PREFIX = $ENV{PREFIX};
    $opts{PREFIX} = $PREFIX;
}
else {
    $PREFIX = "/usr/local";
}

######################################################################
# HTML FILES
######################################################################

if ($ENV{HTMLDIR}) {
    $HTMLDIR = $ENV{HTMLDIR};
}
else {
    $HTMLDIR = "$PREFIX/htdocs";
}
#$opts{'INST_HTMLLIBDIR'} = 'htdocs';        # local build area
#$opts{'INSTALLHTMLPRIVLIBDIR'} = "$HTMLDIR/$opts{NAME}";  # install area

######################################################################
# CGI SCRIPTS
######################################################################

if ($ENV{CGIDIR}) {
    $CGIDIR = $ENV{CGIDIR};
}
else {
    $CGIDIR = "$PREFIX/cgi-bin";
}
#$opts{'INST_HTMLSCRIPTDIR'} = 'bin';        # local build area
#$opts{'INSTALLHTMLSCRIPTDIR'} = "$CGIDIR";  # install area

######################################################################
# MAKE THE MAKEFILE
######################################################################

WriteMakefile(%opts);

sub MY::htmlifypods {
    my($self) = shift;
    return "\nhtmlifypods :\n\t$self->{NOECHO}\$(NOOP)\n";
}

sub MY::manifypods {
    my($self) = shift;
    return "\nmanifypods :\n\t$self->{NOECHO}\$(NOOP)\n";
}

sub MY::postamble {

    return <<EOF;

all ::
	cp bin/app $CGIDIR/app
	chmod +x $CGIDIR/app
EOF
}

