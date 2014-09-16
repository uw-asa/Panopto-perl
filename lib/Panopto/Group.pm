package Panopto::Group;

use strict;
use warnings;

use Panopto::Interface::UserManagement;


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
    $id =~ /^\{?[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}\}?$/i
        or return undef;

    # Query by guid
    $som = $soap->GetGroup(
        Panopto->AuthenticationInfo,
        SOAP::Data->prefix('tns')->name( groupId => $id ),
        );

    return ( 0, $som->fault->{ 'faultstring' } )
        if $som->fault;

    return undef
        unless ref $som->result eq 'HASH';

    for my $key ( keys %{$som->result} ) {
        $self->{$key} = defined($som->result->{$key}) ? $som->result->{$key} : '';
    }

    return $self->Id;
}


sub Delete {
    my $self = shift;

    my $soap = new Panopto::Interface::UserManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my $som = $soap->DeleteGroup(
        Panopto->AuthenticationInfo,
        SOAP::Data->prefix('tns')->name( groupId => $self->Id ),
        );

    return ( 0, $som->fault->{ 'faultstring' } )
        if $som->fault;

    return ( 1, "Group deleted" );
}


sub AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD;
    my $method;

    if ( ($method) = $AUTOLOAD =~ /.*::(\w+)/ and defined($self->{$method}) ) {
        return $self->{$method};
    }

    return ( undef, "Method $AUTOLOAD not defined" );
}


1;
