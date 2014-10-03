package Panopto::Groups;

use strict;
use warnings;

use Panopto::Group;


sub new  {
    my $class = shift;
    my $self  = {};
    bless ($self, $class);

    return $self;
}



sub ListGroups {
    my $self = shift;
    my %args = (
        MaxNumberResults => 100,
        PageNumber       => 0,
        @_,
        );

    my $soap = new Panopto::Interface::UserManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my $som = $soap->ListGroups(
        Panopto->AuthenticationInfo,
        SOAP::Data->prefix('tns')->name(
            pagination => \SOAP::Data->value(
                SOAP::Data->name( MaxNumberResults => $args{'MaxNumberResults'} )->attr({xmlns => 'http://schemas.datacontract.org/2004/07/Panopto.Server.Services.PublicAPI.V40'}),
                SOAP::Data->name( PageNumber => $args{'PageNumber'} )->attr({xmlns => 'http://schemas.datacontract.org/2004/07/Panopto.Server.Services.PublicAPI.V40'}),
            )
        ),
        );

    $self->{'group_list'} = undef;

    return undef
        if $som->fault;

    return 0
        unless $som->result->{'TotalResultCount'};

    my @results;
    if ( ref $som->result->{'PagedResults'}->{'Group'} ne 'ARRAY' ) {
        push @results, $som->result->{'PagedResults'}->{'Group'};
    } else {
        push @results, @{$som->result->{'PagedResults'}->{'Group'}};
    }

    for my $result (@results) {
        my $Group = Panopto::Group->new(%$result);
        push @{$self->{'group_list'}}, $Group;
    }

    return $som->result->{'TotalResultCount'};
}



sub FindByName {
    my $self = shift;
    my $groupName = shift;

    my $soap = new Panopto::Interface::UserManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my $som = $soap->GetGroupsByName(
        Panopto->AuthenticationInfo,
        SOAP::Data->prefix('tns')->name('groupName')->type('string')->value($groupName),
        );

    $self->{'group_list'} = undef;

    return undef
        if $som->fault;

    return 0 unless $som->result && $som->result->{'Group'};

    my @results;
    if ( ref $som->result->{'Group'} ne 'ARRAY' ) {
        push @results, $som->result->{'Group'};
    } else {
        push @results, @{$som->result->{'Group'}};
    }

    for my $result (@results) {
        my $Group = Panopto::Group->new(%$result);
        push @{$self->{'group_list'}}, $Group;
    }

    return scalar(@{$self->{'group_list'}});
}



sub List {
    my $self = shift;

    return () unless $self->{'group_list'};

    return @{$self->{'group_list'}};
}


1;
