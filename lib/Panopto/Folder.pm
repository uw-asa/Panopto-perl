package Panopto::Folder;

use strict;
use warnings;

use Panopto::Interface::SessionManagement;
use SOAP::Lite +trace => qw(debug);


sub new  {
    my $class = shift;
    my $self  = {};
    bless ($self, $class);

    return $self;
}


sub Create {
    my $self = shift;
    my %args = (
        name         => undef, # string
        parentFolder => undef, # guid
        isPublic     => undef, # boolean
        @_
        );

    my $soap = new Panopto::Interface::SessionManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my $som = $soap->AddFolder(
        Panopto->AuthenticationInfo,
        SOAP::Data->prefix('tns')->name( name => $args{'name'} ),
        SOAP::Data->prefix('tns')->name( parentFolder => $args{'parentFolder'} ),
        SOAP::Data->prefix('tns')->name( isPublic => $args{'isPublic'}?'true':'false' ),
        );

    return ( 0, $som->fault->{ 'faultstring' } )
        if $som->fault;

    for my $key ( keys %$som->result ) {
        $self->{$key} = $som->result->{$key};
    }

    return $self->Id;
}


sub Load {
    my $self = shift;
    my $id = shift;

    my $soap = new Panopto::Interface::SessionManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my $som;
    if ( $id =~ /^\{?[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}\}?$/i ) {
        # Query by guid
        $som = $soap->GetFoldersById(
            Panopto->AuthenticationInfo,
            SOAP::Data->prefix('tns')->name(
                folderIds => \SOAP::Data->value(
                    SOAP::Data->prefix('ser')->name( guid => $id ),
                )
            ) );
    }
    else {
        # Query by ExternalId
        $som = $soap->GetFoldersByExternalId(
            Panopto->AuthenticationInfo,
            SOAP::Data->prefix('tns')->name(
                folderExternalIds => \SOAP::Data->value(
                    SOAP::Data->prefix('ser')->name( string => $id ),
                )
            ) );
    }

    return ( 0, $som->fault->{ 'faultstring' } )
        if $som->fault;

    return undef
        unless $som->result->{'Folder'};

    for my $key ( keys %{$som->result->{'Folder'}} ) {
        $self->{$key} = $som->result->{'Folder'}->{$key};
    }

    return $self->Id;
}


sub Id {
    my $self = shift;

    return $self->{'Id'};
}


sub ExternalId {
    my $self = shift;

    return $self->{'ExternalId'};
}


sub SetExternalId {
    my $self = shift;
    my $externalId = shift;

    my $soap = new Panopto::Interface::SessionManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my $som = $soap->UpdateFolderExternalId(
        Panopto->AuthenticationInfo,
        SOAP::Data->prefix('tns')->name( folderId => $self->Id ),
        SOAP::Data->prefix('tns')->name( externalId => $externalId ),
    );

    return ( 0, $som->fault->{ 'faultstring' } )
        if $som->fault;

    return 1;
}


sub Description {
    my $self = shift;

    return $self->{'Description'};
}


sub SetDescription {
    my $self = shift;
    my $description = shift;

    my $soap = new Panopto::Interface::SessionManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my $som = $soap->UpdateFolderDescription(
        Panopto->AuthenticationInfo,
        SOAP::Data->prefix('tns')->name( folderId => $self->Id ),
        SOAP::Data->prefix('tns')->name( description => $description ),
    );

    return ( 0, $som->fault->{ 'faultstring' } )
        if $som->fault;

    return 1;
}


sub State {
    my $self = shift;

    return $self->{'State'};
}


1;
