package Panopto::RemoteRecorder;

use strict;
use warnings;

use Panopto::Interface::RemoteRecorderManagement;


sub new  {
    my $class = shift;
    my $self  = { @_ };
    bless ($self, $class);

    return $self;
}


sub Load {
    my $self = shift;
    my $id = shift;

    my $soap = new Panopto::Interface::RemoteRecorderManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my $som;
    if ( $id =~ /^\{?[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}\}?$/i ) {
        # Query by guid
        $som = $soap->GetRemoteRecordersById(
            Panopto->AuthenticationInfo,
            SOAP::Data->prefix('tns')->name('remoteRecorderIds')->attr({xmlns => 'http://schemas.microsoft.com/2003/10/Serialization/Arrays'})->value(
                \SOAP::Data->value(
                    SOAP::Data->name( guid => $id ),
                )
            ) );
    }
    else {
        # Query by ExternalId
        $som = $soap->GetRemoteRecordersByExternalId(
            Panopto->AuthenticationInfo,
            SOAP::Data->prefix('tns')->name('externalIds')->attr({xmlns => 'http://schemas.microsoft.com/2003/10/Serialization/Arrays'})->value(
                \SOAP::Data->value(
                    SOAP::Data->name( string => $id ),
                )
            ) );
    }

    return undef
        if $som->fault;

    return undef
        unless $som->result->{'RemoteRecorder'};

    for my $key ( keys %{$som->result->{'RemoteRecorder'}} ) {
        $self->{$key} = defined($som->result->{'RemoteRecorder'}->{$key}) ? $som->result->{'RemoteRecorder'}->{$key} : '';
    }

    return $self->Id;
}


sub SetExternalId {
    my $self = shift;
    my $externalId = shift;

    my $soap = new Panopto::Interface::RemoteRecorderManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my $som = $soap->UpdateRemoteRecorderExternalId(
        Panopto->AuthenticationInfo,
        SOAP::Data->prefix('tns')->name( remoteRecorderId => $self->Id ),
        SOAP::Data->prefix('tns')->name( externalId => $externalId ),
    );

    return ( 0, $som->fault->{ 'faultstring' } )
        if $som->fault;

    return 1;
}


=head2 ScheduledRecordings

    returns hashref: { guid => [ <array of guids> ] }

=cut

sub ScheduledRecordings {
    my $self = shift;

    return undef
        unless $self->{'ScheduledRecordings'};

    return { guid => [ $self->{'ScheduledRecordings'}->{'guid'} ] }
        if ref $self->{'ScheduledRecordings'}->{'guid'} ne 'ARRAY';

    return $self->{'ScheduledRecordings'};
}


sub ScheduleRecording {
    my $self = shift;
    my %args = (
        name        => undef, # string
        folderId    => undef, # guid
        isBroadcast => undef, # boolean
        start       => undef, # timestamp
        end         => undef, # timestamp
        @_
        );

    my $RecorderId = SOAP::Data->new(
#        type  => 'ser:guid',
        name  => 'RecorderId',
        value => $self->Id,
        );

    my $SuppressPrimary = SOAP::Data->new(
#        type  => 'boolean',
        name  => 'SuppressPrimary',
        value => 'false',
        );

    my $SuppressSecondary = SOAP::Data->new(
#        type  => 'boolean',
        name  => 'SuppressSecondary',
        value => 'false',
        );

    my $RecorderSettings = SOAP::Data->new(
#        type  => 'tns:RecorderSettings',
        name  => 'RecorderSettings',
        )->value( [ $RecorderId, $SuppressPrimary, $SuppressSecondary ] );

    my $recorderSettings = SOAP::Data->new(
        prefix => 'tns',
#        type  => 'api:ArrayOfRecorderSettings',
        name  => 'recorderSettings',
        attr  => {xmlns => 'http://schemas.datacontract.org/2004/07/Panopto.Server.Services.PublicAPI.V40'},
        )->value( \$RecorderSettings );

    my $soap = new Panopto::Interface::RemoteRecorderManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my $som = $soap->ScheduleRecording(
        Panopto->AuthenticationInfo,
        SOAP::Data->prefix('tns')->name( name => $args{'name'} ),
        SOAP::Data->prefix('tns')->name( folderId => $args{'folderId'} ),
        SOAP::Data->prefix('tns')->name( isBroadcast => $args{'isBroadcast'}?'true':'false' ),
        SOAP::Data->prefix('tns')->name( start => SOAP::Utils::format_datetime(gmtime($args{'start'})) ),
        SOAP::Data->prefix('tns')->name( end => SOAP::Utils::format_datetime(gmtime($args{'end'})) ),
        $recorderSettings,
        );

    return ( undef, $som->fault->{ 'faultstring' } )
        if $som->fault;

    return ( undef, "Conflicting sessions found" )
        unless $som->result->{'ConflictsExist'} eq 'false';

    my $result = $som->result->{'SessionIDs'};

    return $result->{'guid'};
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
