
package Apache::Framework::App;

use Apache ();
use App;

my %env = %ENV;
my $context;

sub handler {
    my $r = shift;

    if ($ENV{PATH_INFO} eq "/show") {
        &show($r);
        return;
    }

    my ($msg, $response);

    # INITIALIZE THE CONTEXT THE FIRST TIME THIS APACHE CHILD PROCESS
    # RECEIVES A REQUEST (should I do this sooner? at child init?)
    # (so that the first request does not need to bear the extra burden)

    # Also, the App class would cache the $context for me
    # if I didn't want to cache it myself. But then I would have to 
    # prepare the %initconf every request. hmmm...
    # I don't suppose the $r->dir_config() call is expensive.

    if (!defined $context) {
        my %initconf = %{$r->dir_config()};
        if (!defined $initconf{contextClass}) {
            $initconf{contextClass} = "App::Context::ModPerl";
        }
        eval {
            $context = App->context(\%initconf);
        };
        $msg = $@ if ($@);
    }

    # this should always be true
    if (defined $context) {
        # the response will be emitted from within dispatch_events()
        $context->dispatch_events();
    }
    else {
        # we had an error (maybe App-Context not installed? Perl @INC not set?)
        $response = <<EOF;
Content-type: text/plain

Unable to create an App::Context.
$msg

EOF
        $r->print($response);
    }
}

sub show {
    my $r = shift;
    my $header = <<EOF;
Content-type: text/plain

Welcome to Apache::Framework::App

EOF
    $r->print($header);
    print $r->as_string();
    $r->print("\n");
    $r->print("ENVIRONMENT VARIABLES\n");
    $r->print("\n");
    foreach my $var (sort keys %ENV) {
        $r->print("$var=$ENV{$var}\n");
    }
    $r->print("\n");
    $r->print("ENVIRONMENT VARIABLES (at startup)\n");
    $r->print("\n");
    foreach my $var (sort keys %env) {
        $r->print("$var=$env{$var}\n");
    }
    $r->print("\n");
    $r->print("DIRECTORY CONFIG\n");
    $r->print("\n");
    my %initconf = %{$r->dir_config()};
    foreach my $var (sort keys %initconf) {
        $r->print("$var=$initconf{$var}\n");
    }
}

1;

