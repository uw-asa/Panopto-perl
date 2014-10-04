package Panopto::Users;

use strict;
use warnings;

use Panopto::User;


sub new  {
    my $class = shift;
    my $self  = {};
    bless ($self, $class);

    $self->Find(@_) if @_;

    return $self;
}



sub ListUsers {
    my $self = shift;
    my %args = (
        MaxNumberResults => 50,
        PageNumber       => 0,
        SortBy           => 'UserKey', # Role, Added, LastLogOn, Email, FullName
        SortIncreasing   => 'true',
        searchQuery      => undef,
        @_,
        );

    my $soap = new Panopto::Interface::UserManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my $som = $soap->ListUsers(
        Panopto->AuthenticationInfo,
        SOAP::Data->prefix('tns')->name(
            parameters => \SOAP::Data->value(
                SOAP::Data->attr({xmlns => 'http://schemas.datacontract.org/2004/07/Panopto.Server.Services.PublicAPI.V40'})->name(
                    Pagination => \SOAP::Data->value(
                        SOAP::Data->name( MaxNumberResults => $args{'MaxNumberResults'} ),
                        SOAP::Data->name( PageNumber => $args{'PageNumber'} ),
                    )
                ),
                SOAP::Data->attr({xmlns => 'http://schemas.datacontract.org/2004/07/Panopto.Server.Services.PublicAPI.V40'})->name( SortBy => $args{'SortBy'} ),
                SOAP::Data->attr({xmlns => 'http://schemas.datacontract.org/2004/07/Panopto.Server.Services.PublicAPI.V40'})->name( SortIncreasing => $args{'SortIncreasing'} ),
            ),
        ),
        SOAP::Data->prefix('tns')->name( searchQuery => $args{'searchQuery'} ),
        );

    $self->{'user_list'} = undef;

    return undef
        if $som->fault;

    return 0
        unless $som->result->{'PagedResults'}->{'User'};

    my @results;
    if ( ref $som->result->{'PagedResults'}->{'User'} ne 'ARRAY' ) {
        push @results, $som->result->{'PagedResults'}->{'User'};
    } else {
        push @results, @{$som->result->{'PagedResults'}->{'User'}};
    }

    for my $result (@results) {
        my $User = Panopto::User->new(%$result);
        push @{$self->{'user_list'}}, $User;
    }

    return $som->result->{'TotalResultCount'};
}



=head2 Find

    Load Panopto::User objects from the server

    takes userIds (guid). Can be a single value or an array

=cut

sub Find {
    my $self = shift;
    my %args = (
        guid => undef,
        @_,
        );

    my $soap = new Panopto::Interface::UserManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my $som;

    $som = $soap->GetUsers(
        Panopto->AuthenticationInfo,
        SOAP::Data->prefix('tns')->name('userIds')->attr({xmlns => 'http://schemas.microsoft.com/2003/10/Serialization/Arrays'})->value(
            \SOAP::Data->value(
                SOAP::Data->name( guid => $args{'guid'} )
            )
        ) );

    $self->{'user_list'} = undef;

    return undef
        if $som->fault;

    return undef
        unless $som->result->{'User'};

    my @results;
    if ( ref $som->result->{'User'} ne 'ARRAY' ) {
        push @results, $som->result->{'User'};
    } else {
        push @results, @{$som->result->{'User'}};
    }

    for my $result (@results) {
        my $User = Panopto::User->new(%$result);
        push @{$self->{'user_list'}}, $User;
    }

    return scalar(@{$self->{'user_list'}});
}


sub List {
    my $self = shift;

    return undef unless $self->{'user_list'};

    return @{$self->{'user_list'}};
}


1;
