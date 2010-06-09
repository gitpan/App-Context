
#############################################################################
## $Id: ResourceLocker.pm 6783 2006-08-11 17:43:28Z spadkins $
#############################################################################

package App::ResourceLocker;
$VERSION = (q$Revision: 6783 $ =~ /(\d[\d\.]*)/)[0];  # VERSION numbers generated by svn

use App;
use App::Service;
@ISA = ( "App::Service" );

use strict;

=head1 NAME

App::ResourceLocker - Interface for locking shared resources

=head1 SYNOPSIS

    use App;

    $context = App->context();
    $srs = $context->service("ResourceLocker");  # or ...
    $srs = $context->shared_resource_set();

=head1 DESCRIPTION

A ResourceLocker service represents a collection of "advisory" (or "cooperative")
resource locks. 

=cut

#############################################################################
# CLASS GROUP
#############################################################################

=head1 Class Group: ResourceLocker

The following classes might be a part of the ResourceLocker Class Group.

=over

=item * Class: App::ResourceLocker

=item * Class: App::ResourceLocker::IPCLocker

=item * Class: App::ResourceLocker::IPCSemaphore

=item * Class: App::ResourceLocker::BerkeleyDB

=back

=cut

#############################################################################
# CLASS
#############################################################################

=head1 Class: App::ResourceLocker

A ResourceLocker service represents a collection of "advisory" (or "cooperative")
resource locks.  These can be used to synchronize access to and modification
of shared resources such as are stored in a SharedDatastore.

 * Throws: App::Exception::ResourceLocker
 * Since:  0.01

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
# lock()
#############################################################################

=head2 lock()

    * Signature: $resource_name = $srs->lock($resource_pool);
    * Signature: $resource_name = $srs->lock($named);
    * Param:     $resource_pool          string
    * Param:     resourcePool            string
    * Param:     nonBlocking             boolean
    * Param:     nonExclusive            boolean
    * Param:     maxWaitTimeMS           integer
    * Return:    $resource_name          string
    * Throws:    App::Exception::ResourceLocker
    * Since:     0.01

    Sample Usage: 

    $context = App->context();
    $srs = $context->service("ResourceLocker");
    $srs->lock("shmem01");

The lock() method on a ResourceLocker is for the purposes of cooperative
resource locking.

=cut

sub lock {
    my ($self, $arg) = @_;
    my ($resource_pool, $resource_name);
    if (ref($arg) eq "HASH") {
        $resource_pool = $arg->{resourcePool};
    }
    elsif (ref($arg) eq "") {
        $resource_pool = $arg;
    }
    return undef if (! $resource_pool);

    # this is a dummy implementation. it does no real locking.
    # it returns a resource name which is the same as the resource pool

    $resource_name = $resource_pool;
    return ($resource_name);
}

#############################################################################
# unlock()
#############################################################################

=head2 unlock()

    * Signature: $srs->unlock($resource_name);
    * Param:     $resource_name          string
    * Return:    void
    * Throws:    App::Exception::ResourceLocker
    * Since:     0.01

    Sample Usage: 

    $context = App->context();
    $srs = $context->service("ResourceLocker");
    $srs->unlock("shmem01");

=cut

sub unlock {
    my ($self, $resource_name) = @_;
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

Returns 'ResourceLocker';

    * Signature: $service_type = App::ResourceLocker->service_type();
    * Param:     void
    * Return:    $service_type  string
    * Since:     0.01

    $service_type = $rlock->service_type();

=cut

sub service_type () { 'ResourceLocker'; }

=head1 ACKNOWLEDGEMENTS

 * Author:  Stephen Adkins <spadkins@gmail.com>
 * License: This is free software. It is licensed under the same terms as Perl itself.

=head1 SEE ALSO

L<C<App::Context>|App::Context>,
L<C<App::Service>|App::Service>

=cut

1;
