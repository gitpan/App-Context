
#############################################################################
## $Id: Authentication.pm,v 1.3 2004/09/02 20:53:32 spadkins Exp $
#############################################################################

package App::Authentication;

use App;
use App::Service;
@ISA = ( "App::Service" );

use strict;

=head1 NAME

App::Authentication - Interface for authentication and authorization

=head1 SYNOPSIS

    use App;

    $context = App->context();
    $security = $context->service("Authentication");  # or ...
    $security = $context->authentication();

    ... TBD ...

=head1 DESCRIPTION

An Authentication service is a means by which a user may be authenticated.

=cut

#############################################################################
# CLASS GROUP
#############################################################################

=head1 Class Group: Authentication

The following classes might be a part of the Authentication Class Group.

=over

=item * Class: App::Authentication

=item * Class: App::Authentication::Passwd

=item * Class: App::Authentication::DBI

=item * Class: App::Authentication::Repository

=item * Class: App::Authentication::SMB

=item * Class: App::Authentication::LDAP

=item * Class: App::Authentication::Radius

=item * Class: App::Authentication::Kerberos

=item * Class: App::Authentication::SSL

=item * Class: App::Authentication::DCE

=back

=cut

#############################################################################
# CLASS
#############################################################################

=head1 Class: App::Authentication

A Authentication service is a means by which a user may be authenticated
and by which he may be authorized to perform specific operations.

 * Throws: App::Exception::Authentication
 * Since:  0.01

=head2 Class Design

...

=cut

#############################################################################
# CONSTRUCTOR METHODS
#############################################################################

=head1 Constructor Methods:

=cut

#############################################################################
# new()
#############################################################################

=head2 new()

The constructor is inherited from
L<C<App::Service>|App::Service/"new()">.

=cut

#############################################################################
# PUBLIC METHODS
#############################################################################

=head1 Public Methods:

=cut

#############################################################################
# get_username()
#############################################################################

=head2 get_username()

    * Signature: $username = $auth->get_username();
    * Param:     void
    * Return:    $username        string
    * Throws:    App::Exception::Authentication
    * Since:     0.01

    Sample Usage:

    $username = $auth->get_username();

=cut

sub get_username {
    my ($self) = @_;
    my $username = $ENV{REMOTE_USER} || getlogin || (getpwuid($<))[0] || "guest";
    return($username);
}

#############################################################################
# Method: service_type()
#############################################################################

=head2 service_type()

    * Signature: $service_type = App::Authentication->service_type();
    * Param:     void
    * Return:    $service_type  string
    * Since:     0.01

    $service_type = $authen->service_type();

Returns 'Authentication';

=cut

sub service_type () { 'Authentication'; }

=head1 ACKNOWLEDGEMENTS

 * Author:  Stephen Adkins <stephen.adkins@officevision.com>
 * License: This is free software. It is licensed under the same terms as Perl itself.

=head1 SEE ALSO

L<C<App::Context>|App::Context>,
L<C<App::Service>|App::Service>

=cut

1;

