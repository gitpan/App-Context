#!/usr/local/bin/perl -w

use Test::More qw(no_plan);
use lib "lib";
use lib "../lib";

BEGIN {
   use_ok("App::Reference");
}

use strict;

#$App::DEBUG = 0;
my ($ref, $branch);

$ref = App::Reference->new();
ok(defined $ref, "constructor ok");
isa_ok($ref, "App::Reference", "right class");

$ref->set("x.y.z.pi", 3.1416);
is($ref->get("x.y.z.pi"), 3.1416, "get x.y.z.pi");

$branch = $ref->get_branch("x.y.z");
is($branch->{pi}, 3.1416, "get_branch()");

$branch = $ref->get_branch("zeta.alpha");
ok(! defined $branch, "non-existent branch");

$branch = $ref->get_branch("zeta.alpha", 1);
ok(defined $branch, "newly existent branch");

exit 0;

