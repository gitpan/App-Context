
#############################################################################
## $Id: Authentication.pm,v 1.1 2002/10/07 21:55:58 spadkins Exp $
#############################################################################

package App::Security;

use App;
use App::Service;
@ISA = ( "App::Service" );

use strict;

=head1 NAME

App::Security - Interface for authentication and authorization

=head1 SYNOPSIS

    use App;

    $context = App->context();
    $security = $context->service("Security");  # or ...
    $security = $context->security();

    ... TBD ...

=head1 DESCRIPTION

A Security service is a means by which a user may be authenticated
and by which he may be authorized to perform specific operations.

=cut

#############################################################################
# CLASS GROUP
#############################################################################

=head1 Class Group: Security

The following classes might be a part of the Security Class Group.

=over

=item * Class: App::Security

=item * Class: App::Security::Htpasswd

=item * Class: App::Security::Passwd

=item * Class: App::Security::DBI

=item * Class: App::Security::Repository

=item * Class: App::Security::SMB

=item * Class: App::Security::LDAP

=item * Class: App::Security::Radius

=item * Class: App::Security::Kerberos

=item * Class: App::Security::SSL

=item * Class: App::Security::DCE

=back

=cut

#############################################################################
# CLASS
#############################################################################

=head1 Class: App::Security

A Security service is a means by which a user may be authenticated
and by which he may be authorized to perform specific operations.

 * Throws: App::Exception::Security
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
# TBD()
#############################################################################

=head2 TBD()

    * Signature: $tbd_return = $repository->tbd($tbd_param);
    * Param:     $tbd_param         integer
    * Return:    $tbd_return        integer
    * Throws:    App::Exception::Repository
    * Since:     0.01

    Sample Usage:

    $tbd_return = $repository->tbd($tbd_param);

=cut

sub tbd {
    my ($self) = @_;
}

#############################################################################
# PROTECTED METHODS
#############################################################################

=head1 Protected Methods:

=cut

#############################################################################
# Method: service_type()
#############################################################################

=head2 service_type()

Returns 'Security';

    * Signature: $service_type = App::Security->service_type();
    * Param:     void
    * Return:    $service_type  string
    * Since:     0.01

    $service_type = $authen->service_type();

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

