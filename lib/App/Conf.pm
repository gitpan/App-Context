
#############################################################################
## $Id: Conf.pm 3259 2003-04-29 19:46:33Z spadkins $
#############################################################################

package App::Conf;
$VERSION = do { my @r=(q$Revision: 3259 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r};

use App;
use App::Reference;
@ISA = ( "App::Reference" );

use strict;

#############################################################################
# dump()
#############################################################################

=head2 dump()

    * Signature: $perl = $conf->dump();
    * Param:     void
    * Return:    $perl      text
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    $conf = $context->conf();
    print $conf->dump(), "\n";

=cut

use Data::Dumper;

sub dump {
    my ($self) = @_;
    my %copy = %$self;
    delete $copy{context};   # don't dump the reference to the context itself
    my $d = Data::Dumper->new([ \%copy ], [ "conf" ]);
    $d->Indent(1);
    return $d->Dump();
}

1;

