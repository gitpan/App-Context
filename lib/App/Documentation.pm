
#############################################################################
## $Id: Documentation.pm,v 1.1 2006/03/11 15:36:40 spadkins Exp $
#############################################################################

package App::Documentation;
$VERSION = (q$Revision: 0 $ =~ /(\d[\d\.]*)/)[0];  # VERSION numbers generated by cvs

use strict;

=head1 NAME

App::Documentation - Documentation for developing, installing, and administering applications in Perl

=head1 SYNOPSIS

    (for "man" below, you can substitute "perldoc" instead if on non Unix platform)
    man App::faq                  # frequently asked questions
    man App::devguide             # a developer's guide
    man App::installguide         # an installer's guide
    man App::installguide::win32  # an installer's guide (issues specific to Win32)
    man App::adminguide           # an administrator's guide
    man App::adminguide::cvs      # an administrator's guide (CVS issues)
    man App::perlstyle            # a perl style guide
    man App::datetime             # understanding date/time handling in Perl
    man App::exceptions           # understanding exception handling in Perl

=head1 DESCRIPTION

TMTOWTDI. "There's more than one way to do it."
This is the Perl motto. 
However, in some circumstances, this "freedom" results in a lack of guidance.

In my experience, group development of complex systems benefits greatly from the
establishment of "best practices".  These "best practices" can be seen as OGWTDI
("One good way to do it").  This is a collection of documentation to set
forth some "best practices" for development of complex systems in Perl.

I do not claim that these "best practices" are in some absolute sense, the truly
*best* practices.  They are simply my recommendations, and they are reasonable and self-consistent. 
They might better be called "my recommended practices."

If you would like to contribute to the development of these documents, please feel free.
I welcome input from anyone willing to invest the time to do so.
However, if you find them valuable, but disagree with some items, I have no interest in arguing.
Just go ahead and change them and use the modified documentation in your organization.

Do these documents lay out a set of "standards" for Perl development?
I prefer to call them "best practices" rather than "standards".
You call them what you like.

=head1 ACKNOWLEDGEMENTS

 * Author:  Stephen Adkins <spadkins@gmail.com>
 * License: This is free software. It is licensed under the same terms as Perl itself.

=head1 SEE ALSO

=cut

sub new {
    my $this = {};
    bless $this, "App::Documentation";
    return($this);
}

1;
