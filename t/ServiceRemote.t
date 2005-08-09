#!/usr/local/bin/perl -w

use Test::More qw(no_plan);
use lib "lib";
use lib "../lib";

use App::Options (
    options => [ qw(app_remote_cgi_url) ],
);

use App;

my ($context, $dir);
$dir = ".";
$dir = "t" if (! -f "app.pl");

$context = App->context(
    conf_file => "",
    conf => {
        SharedDatastore => {
            dict => {
                class => "App::SharedDatastore",
            },
            localdict => {
                class => "App::Service::Remote",
                remote_service => "SharedDatastore",
                remote_name => "dict",
                call_dispatcher => "local",
            },
            remotedict => {
                class => "App::Service::Remote",
                remote_service => "SharedDatastore",
                remote_name => "dict",
                call_dispatcher => "localhost",
            },
        },
        CallDispatcher => {
            local => {
                class => "App::CallDispatcher",
            },
            localhost => {
                class => "App::CallDispatcher::HTTPSimple",
                url => $App::options{app_remote_cgi_url},
            },
        },
    },
);

my $dict = $context->shared_datastore("localdict");
ok(defined $dict, "constructor ok");
isa_ok($dict, "App::Service::Remote", "ini right class");
is($dict->service_type(), "SharedDatastore", "ini right service type");
my $city = $dict->get("city");

exit 0;

