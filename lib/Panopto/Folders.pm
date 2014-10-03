package Panopto::Folders;

use strict;
use warnings;

use Panopto::Folder;


sub new  {
    my $class = shift;
    my $self  = {};
    bless ($self, $class);

    return $self;
}



sub FindByExternalId {
    my $self = shift;
    my @externalIds = @_;

    my $soap = new Panopto::Interface::SessionManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    map { s/&/&amp;/g } @externalIds;

    my $som = $soap->GetAllFoldersByExternalId(
        Panopto->AuthenticationInfo,
        SOAP::Data->prefix('tns')->name('folderExternalIds')->attr({xmlns => 'http://schemas.microsoft.com/2003/10/Serialization/Arrays'})->value(
            \SOAP::Data->value(
                SOAP::Data->name( string => \@externalIds )
            )
        ) );

    $self->{'folder_list'} = undef;

    return ( undef, $som->fault->{ 'faultstring' } )
        if $som->fault;

    return 0 unless $som->result && $som->result->{'Folder'};

    my @results;
    if ( ref $som->result->{'Folder'} ne 'ARRAY' ) {
        push @results, $som->result->{'Folder'};
    } else {
        push @results, @{$som->result->{'Folder'}};
    }

    for my $result (@results) {
        my $Folder = Panopto::Folder->new(%$result);
        push @{$self->{'folder_list'}}, $Folder;
    }

    return scalar(@{$self->{'folder_list'}});
}


sub ListFolders {
    my $self = shift;
    my %args = (
        MaxNumberResults => 50,
        PageNumber       => 0,
        ParentFolderId   => undef,
        PublicOnly       => 'false',
        SortBy           => 'Name', # Sessions, Relavance (sic)
        SortIncreasing   => 'true',
        searchQuery      => undef,
        @_,
        );

    my $soap = new Panopto::Interface::SessionManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my $som = $soap->GetFoldersList(
        Panopto->AuthenticationInfo,
        SOAP::Data->prefix('tns')->name(
            request => \SOAP::Data->value(
                SOAP::Data->attr({xmlns => 'http://schemas.datacontract.org/2004/07/Panopto.Server.Services.PublicAPI.V40'})->name(
                    Pagination => \SOAP::Data->value(
                        SOAP::Data->name( MaxNumberResults => $args{'MaxNumberResults'} ),
                        SOAP::Data->name( PageNumber => $args{'PageNumber'} ),
                    )
                ),
                SOAP::Data->attr({xmlns => 'http://schemas.datacontract.org/2004/07/Panopto.Server.Services.PublicAPI.V40'})->name( ParentFolderId => $args{'ParentFolderId'} ),
                SOAP::Data->attr({xmlns => 'http://schemas.datacontract.org/2004/07/Panopto.Server.Services.PublicAPI.V40'})->name( PublicOnly => $args{'PublicOnly'} ),
                SOAP::Data->attr({xmlns => 'http://schemas.datacontract.org/2004/07/Panopto.Server.Services.PublicAPI.V40'})->name( SortBy => $args{'SortBy'} ),
                SOAP::Data->attr({xmlns => 'http://schemas.datacontract.org/2004/07/Panopto.Server.Services.PublicAPI.V40'})->name( SortIncreasing => $args{'SortIncreasing'} ),
            ),
        ),
        SOAP::Data->prefix('tns')->name('searchQuery')->type('string')->value($args{'searchQuery'}),
        );

    $self->{'folder_list'} = undef;

    return undef
        if $som->fault;

    return 0
        unless $som->result->{'TotalNumberResults'};

    my @results;
    if ( ref $som->result->{'Results'}->{'Folder'} ne 'ARRAY' ) {
        push @results, $som->result->{'Results'}->{'Folder'};
    } else {
        push @results, @{$som->result->{'Results'}->{'Folder'}};
    }

    for my $result (@results) {
        my $Folder = Panopto::Folder->new(%$result);
        push @{$self->{'folder_list'}}, $Folder;
    }

    return $som->result->{'TotalNumberResults'};
}



sub List {
    my $self = shift;

    return () unless $self->{'folder_list'};

    return @{$self->{'folder_list'}};
}


1;
