
#############################################################################
## $Id: Conf.pm,v 1.1 2002/09/09 01:34:10 spadkins Exp $
#############################################################################

package App::Conf;
$VERSION = do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r};

use App;
use App::Reference;
@ISA = ( "App::Reference" );

use strict;

# there are no methods for this class yet

1;

