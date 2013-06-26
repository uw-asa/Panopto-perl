package Panopto::Folder;

use strict;
use warnings;

use Panopto;

use Panopto::Interface::SessionManagement;
use SOAP::Lite +trace => qw(debug);


our (
    $auth,
    $soap,
    $Folder,
    );


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

    $soap = new Panopto::Interface::SessionManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    $auth = SOAP::Data->new(
        prefix => 'tns',
        name   => 'auth',
        value  => \SOAP::Data->value(
            SOAP::Data->prefix('api')->name( AuthCode => Panopto->AuthCode ),
            SOAP::Data->prefix('api')->name( UserKey  => Panopto->UserKey ),
        ) );

    my $som;
    $som = $soap->AddFolder(
        $auth,
        SOAP::Data->prefix('tns')->name( name => $args{'name'} ),
        SOAP::Data->prefix('tns')->name( parentFolder => $args{'parentFolder'} ),
        SOAP::Data->prefix('tns')->name( isPublic => $args{'isPublic'}?'true':'false' ),
        );

    return ( 0, $som->fault->{ 'faultstring' } )
        if $som->fault;

    $Folder = $som->result;

    return $self->Id;
}


sub Load {
    my $self = shift;
    my $id = shift;

    $soap = new Panopto::Interface::SessionManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    $auth = SOAP::Data->new(
        prefix => 'tns',
        name   => 'auth',
        value  => \SOAP::Data->value(
            SOAP::Data->prefix('api')->name( AuthCode => Panopto->AuthCode ),
            SOAP::Data->prefix('api')->name( UserKey  => Panopto->UserKey ),
        ) );

    my $som;
    if ( $id =~ /^\{?[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}\}?$/i ) {
        # Query by guid
        $som = $soap->GetFoldersById(
            $auth,
            SOAP::Data->prefix('tns')->name(
                folderIds => \SOAP::Data->value(
                    SOAP::Data->prefix('ser')->name( guid => $id ),
                )
            ) );
    }
    else {
        # Query by ExternalId
        $som = $soap->GetFoldersByExternalId(
            $auth,
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

    $Folder = $som->result->{'Folder'};

    return $self->Id;
}


sub Id {
    my $self = shift;

    return $Folder->{'Id'};
}


sub ExternalId {
    my $self = shift;

    return $Folder->{'ExternalId'};
}


sub SetExternalId {
    my $self = shift;
    my $externalId = shift;

    my $som = $soap->UpdateFolderExternalId(
        $auth,
        SOAP::Data->prefix('tns')->name( folderId => $self->Id ),
        SOAP::Data->prefix('tns')->name( externalId => $externalId ),
    );

    return ( 0, $som->fault->{ 'faultstring' } )
        if $som->fault;

    return 1;
}


sub Description {
    my $self = shift;

    return $Folder->{'Description'};
}


sub SetDescription {
    my $self = shift;
    my $description = shift;

    my $som = $soap->UpdateFolderDescription(
        $auth,
        SOAP::Data->prefix('tns')->name( folderId => $self->Id ),
        SOAP::Data->prefix('tns')->name( description => $description ),
    );

    return ( 0, $som->fault->{ 'faultstring' } )
        if $som->fault;

    return 1;
}


sub State {
    my $self = shift;

    return $Folder->{'State'};
}


1;
