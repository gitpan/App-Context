#!/usr/local/bin/perl -w

use Test::More qw(no_plan);
use lib "lib";
use lib "../lib";

use App::Options (
    options => [ qw(dbhost dbname dbuser dbpass app_remote_cgi_url) ],
);

use App;
use App::Repository;

my ($context, $dir);
$dir = ".";
$dir = "t" if (! -f "app.pl");

$context = App->context(
    conf_file => "",
    conf => {
        Repository => {
            db => {
                class => "App::Repository::MySQL",
                dbhost => $App::options{dbhost},
                dbname => $App::options{dbname},
                dbuser => $App::options{dbuser},
                dbpass => $App::options{dbpass},
            },
            localdb => {
                class => "App::Service::Remote",
                remote_service => "Repository",
                remote_name => "db",
                call_dispatcher => "local",
            },
            remotedb => {
                class => "App::Service::Remote",
                remote_service => "Repository",
                remote_name => "db",
                call_dispatcher => "localhost",
            },
        },
        CallDispatcher => {
            localhost => {
                class => "App::CallDispatcher::HTTPSimple",
                url => $App::options{app_remote_cgi_url},
            },
            local => {
                class => "App::CallDispatcher",
            },
        },
    },
);

my $db = $context->repository("localdb");
ok(defined $db, "constructor ok");
isa_ok($db, "App::Service::Remote", "ini right class");
is($db->service_type(), "Repository", "ini right service type");
my $rows = $db->get_rows("city",{city_cd=>"LAX"},["city_cd","state","country"]);
foreach my $row (@$rows) {
    print " [", join("|",@$row), "]\n";
}

exit 0;

