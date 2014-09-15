package Panopto::RemoteRecorders;

use strict;
use warnings;

use Panopto::RemoteRecorder;
#use SOAP::Lite +trace => qw(debug);


sub new  {
    my $class = shift;
    my $self  = {};
    bless ($self, $class);

    return $self;
}


sub Load {
    my $self = shift;
    my %args = (
        MaxNumberResults => 25,
        PageNumber       => 1,
        SortBy           => 'Name',
        @_,
        );

    use Panopto::Interface::RemoteRecorderManagement;
    my $soap = new Panopto::Interface::RemoteRecorderManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my $som = $soap->ListRecorders(
        Panopto->AuthenticationInfo,
        SOAP::Data->name('Pagination')->attr({xmlns => 'http://schemas.datacontract.org/2004/07/Panopto.Server.Services.PublicAPI.V40'})->value(
            \SOAP::Data->value(
                SOAP::Data->name( MaxNumberResults => $args{'MaxNumberResults'} ),
                SOAP::Data->name( PageNumber => $args{'PageNumber'} ),
            )
        ),
        SOAP::Data->name( SortBy => $args{'SortBy'} )
        );

    $self->{'recorder_list'} = undef;

    return ( undef, $som->fault->{ 'faultstring' } )
        if $som->fault;

    return 0 unless $som->result && $som->result->{'PagedResults'}->{'RemoteRecorder'};

    my @results;
    if ( ref $som->result->{'PagedResults'}->{'RemoteRecorder'} ne 'ARRAY' ) {
        push @results, $som->result->{'PagedResults'}->{'RemoteRecorder'};
    } else {
        push @results, @{$som->result->{'PagedResults'}->{'RemoteRecorder'}};
    }

    for my $result (@results) {
        my $RemoteRecorder = Panopto::RemoteRecorder->new(%$result);
        push @{$self->{'recorder_list'}}, $RemoteRecorder;
    }

    return scalar(@{$self->{'recorder_list'}});

}


sub FindByExternalId {
    my $self = shift;
    my @externalIds = @_;

    my $soap = new Panopto::Interface::RemoteRecorderManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my $som = $soap->GetRemoteRecordersByExternalId(
        Panopto->AuthenticationInfo,
        SOAP::Data->prefix('tns')->name('externalIds')->attr({xmlns => 'http://schemas.microsoft.com/2003/10/Serialization/Arrays'})->value(
            \SOAP::Data->value(
                SOAP::Data->name( string => \@externalIds )
            )
        ) );

    $self->{'recorder_list'} = undef;

    return ( undef, $som->fault->{ 'faultstring' } )
        if $som->fault;

    return 0 unless $som->result && $som->result->{'RemoteRecorder'};

    my @results;
    if ( ref $som->result->{'RemoteRecorder'} ne 'ARRAY' ) {
        push @results, $som->result->{'RemoteRecorder'};
    } else {
        push @results, @{$som->result->{'RemoteRecorder'}};
    }

    for my $result (@results) {
        my $RemoteRecorder = Panopto::RemoteRecorder->new(%$result);
        push @{$self->{'recorder_list'}}, $RemoteRecorder;
    }

    return scalar(@{$self->{'recorder_list'}});
}


sub List {
    my $self = shift;

    return () unless $self->{'recorder_list'};

    return @{$self->{'recorder_list'}};
}


1;
