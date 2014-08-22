package Panopto::User;

use strict;
use warnings;

use Panopto::Interface::UserManagement;
#use SOAP::Lite +trace => qw(debug);


sub new  {
    my $class = shift;
    my $self  = { @_ };
    bless ($self, $class);

    return $self;
}


sub Load {
    my $self = shift;
    my $id = shift;

    my $soap = new Panopto::Interface::UserManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my $som;
    if ( $id =~ /^\{?[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}\}?$/i ) {
        # Query by guid
        $som = $soap->GetUsers(
            Panopto->AuthenticationInfo,
            SOAP::Data->prefix('tns')->name('userIds')->attr({xmlns => 'http://schemas.microsoft.com/2003/10/Serialization/Arrays'})->value(
                \SOAP::Data->value(
                    SOAP::Data->name( guid => $id ),
                )
            ) );
    } else {
        # Query by UserKey
        # Note that this will create the user if they don't exist!
        $som = $soap->GetUserByKey(
            Panopto->AuthenticationInfo,
            SOAP::Data->prefix('tns')->name( userKey => $id ),
            );
        
    }

    return ( 0, $som->fault->{ 'faultstring' } )
        if $som->fault;

    return undef
        unless ref $som->result eq 'HASH';

    my $res = $som->result->{'User'} || $som->result;

    return undef
        unless $res;

    for my $key ( keys %{$res} ) {
        $self->{$key} = defined($res->{$key}) ? $res->{$key} : '';
    }

    return $self->Id;
}


sub Id {
    my $self = shift;

    return $self->{'UserId'};
}


sub UserId {
    my $self = shift;

    return $self->{'UserId'};
}


sub FirstName {
    my $self = shift;

    return $self->{'FirstName'};
}


sub LastName {
    my $self = shift;

    return $self->{'LastName'};
}


sub UserKey {
    my $self = shift;

    return $self->{'UserKey'};
}


sub Email {
    my $self = shift;

    return $self->{'Email'};
}


sub SystemRole {
    my $self = shift;

    return $self->{'SystemRole'};
}


sub UserBio {
    my $self = shift;

    return $self->{'UserBio'};
}

sub EmailSessionNotifications {
    my $self = shift;

    return $self->{'EmailSessionNotifications'};
}


sub UserSettingsUrl {
    my $self = shift;

    return $self->{'UserSettingsUrl'};
}


sub GroupMemberships {
    my $self = shift;

    return undef unless $self->{'GroupMemberships'};

    return { guid => [ $self->{'GroupMemberships'}->{'guid'} ] }
        if ref $self->{'GroupMemberships'}->{'guid'} ne 'ARRAY';

    return $self->{'GroupMemberships'};
}


1;
