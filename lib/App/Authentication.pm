
#############################################################################
## $Id: Authentication.pm 9850 2007-08-17 16:09:40Z spadkins $
#############################################################################

package App::Authentication;
$VERSION = (q$Revision: 9850 $ =~ /(\d[\d\.]*)/)[0];  # VERSION numbers generated by svn

use App;
use App::Service;
@ISA = ( "App::Service" );

use strict;

=head1 NAME

App::Authentication - Interface for authentication and authorization

=head1 SYNOPSIS

    use App;

    $context = App->context();
    $authentication = $context->service("Authentication");  # or ...
    $authentication = $context->authentication();

    if ($authentication->validate_password($username, $password)) {
       ...
    }

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
# validate_password()
#############################################################################

=head2 validate_password()

    * Signature: $username = $auth->validate_password();
    * Param:     void
    * Return:    $username        string
    * Throws:    App::Exception::Authentication
    * Since:     0.01

    Sample Usage:

    $username = $auth->validate_password();

=cut

sub validate_password {
    my ($self, $username, $password) = @_;
    return(1);
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

 * Author:  Stephen Adkins <spadkins@gmail.com>
 * License: This is free software. It is licensed under the same terms as Perl itself.

=head1 SEE ALSO

L<C<App::Context>|App::Context>,
L<C<App::Service>|App::Service>

=cut

1;

