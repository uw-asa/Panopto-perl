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
