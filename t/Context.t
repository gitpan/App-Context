#!/usr/local/bin/perl -w

use Test::More qw(no_plan);
use lib "lib";
use lib "../lib";

BEGIN {
   use_ok("App");
   use_ok("App::Conf::File");
}

my ($conf, $config, $file, $dir);
#$App::DEBUG = 1;

$dir = ".";
$dir = "t" if (! -f "app.pl");
$conf = do "$dir/app.pl";
$config = App->conf();

ok(defined $config, "constructor ok");
isa_ok($config, "App::Conf", "right class");
is_deeply($conf, { %$config }, "conf to depth");

exit 0;

