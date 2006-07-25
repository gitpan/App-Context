#!/usr/local/bin/perl -w

use Test::More qw(no_plan);
use lib "lib";
use lib "../lib";
use lib "t";

BEGIN {
   use_ok("App");
   use_ok("App::Conf::File");
}

my ($conf, $config, $file, $t_dir);
#$App::DEBUG = 1;

$t_dir = ".";
$t_dir = "t" if (! -f "app.pl");
$conf = do "$t_dir/app.pl";
$config = App->conf();

ok(defined $config, "constructor ok");
isa_ok($config, "App::Conf", "right class");
is_deeply($conf, { %$config }, "conf to depth");

{
    $App::options{prefix} = $t_dir;
    my $context = App->context();
    isa_ok($context, "App::Context", "context");
    isa_ok($context, "App::Context::Cmd", "context");

    $context->so_set("pi", undef, 3.1416);
    is($context->so_get("pi"), 3.1416, "so_get(pi)");
    is($context->so_get("default","pi"), 3.1416, "so_get(default,pi)");
    is($context->so_get("default-pi"), 3.1416, "so_get(default-pi)");
    my $obj = $context->session_object("hello",
        class => "AppSessionObjectTest",
    );
    isa_ok($obj, "AppSessionObjectTest", "session_object() instantiation works");
    isa_ok($obj, "App::SessionObject", "session_object() instantiation works (2)");

    my ($retval);
    $retval = $context->send_event({ method => "so_set", args => [ "e", undef, 2.71828 ]});
    is($retval, 1, "send_event() on Context returned proper value");
    is($context->so_get("e"), 2.71828, "send_event() on Context worked");
    $retval = $context->send_event({ service_type => "SessionObject", name => "hello", method => "hello", });
    is($retval, "hello", "send_event() on SessionObject returned proper value");

    my $event_token = $context->send_async_event({ service_type => "SessionObject", name => "hello", method => "hello", },
                                                 { service_type => "SessionObject", name => "hello", method => "finish_hello", });
    # now check the results
    my $results = $context->so_get("results");
    is($results->{event_token}, $event_token, "send_async_event() got right event_token [$event_token]");
    is($results->{returnval}, "hello",    "send_async_event() got right returnval [hello]");
    is($results->{errmsg},    "",         "send_async_event() got right errmsg []");
    is($results->{errnum},    0,          "send_async_event() got right errnum [0]");
}

exit 0;

