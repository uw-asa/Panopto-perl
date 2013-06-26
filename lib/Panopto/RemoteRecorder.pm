package Panopto::RemoteRecorder;

use strict;
use warnings;

use Panopto;

use Panopto::Interface::RemoteRecorderManagement;
use SOAP::Lite +trace => qw(debug);


our (
    $auth,
    $soap,
    $RemoteRecorder,
    );


sub new  {
    my $class = shift;
    my $self  = {};
    bless ($self, $class);

    return $self;
}


sub Load {
    my $self = shift;
    my $id = shift;

    $soap = new Panopto::Interface::RemoteRecorderManagement;

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
    if ( $id =~ /\D/ ) {
        # Query by guid
        $som = $soap->GetRemoteRecordersById(
            $auth,
            SOAP::Data->prefix('tns')->name(
                remoteRecorderIds => \SOAP::Data->value(
                    SOAP::Data->prefix('ser')->name( guid => $id ),
                )
            ) );
    }
    else {
        # Query by ExternalId
        $som = $soap->GetRemoteRecordersByExternalId(
            $auth,
            SOAP::Data->prefix('tns')->name(
                externalIds => \SOAP::Data->value(
                    SOAP::Data->prefix('ser')->name( string => $id ),
                )
            ) );
    }

    return undef
        if $som->fault;

    return undef
        unless $som->result->{'RemoteRecorder'};

    $RemoteRecorder = $som->result->{'RemoteRecorder'};

    return $RemoteRecorder->{'Id'};
}


sub Id {
    my $self = shift;

    return $RemoteRecorder->{'Id'};
}


sub ExternalId {
    my $self = shift;

    return $RemoteRecorder->{'ExternalId'};
}


sub SetExternalId {
    my $self = shift;
    my $externalId = shift;

    my $som = $soap->UpdateRemoteRecorderExternalId(
        $auth,
        SOAP::Data->prefix('tns')->name( remoteRecorderId => $self->Id ),
        SOAP::Data->prefix('tns')->name( externalId => $externalId ),
    );

    return ( 0, $som->fault->{ 'faultstring' } )
        if $som->fault;

    return 1;
}


sub MachineIP {
    my $self = shift;

    return $RemoteRecorder->{'MachineIP'};
}


sub Name {
    my $self = shift;

    return $RemoteRecorder->{'Name'};
}


sub PreviewURL {
    my $self = shift;

    return $RemoteRecorder->{'PreviewURL'};
}


sub SettingsURL {
    my $self = shift;

    return $RemoteRecorder->{'SettingsURL'};
}


sub State {
    my $self = shift;

    return $RemoteRecorder->{'State'};
}


sub ScheduledRecordings {
    my $self = shift;

    return $RemoteRecorder->{'ScheduledRecordings'};
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
        prefix => 'api',
#        type  => 'ser:guid',
        name  => 'RecorderId',
        value => $self->Id,
        );

    my $SuppressPrimary = SOAP::Data->new(
        prefix => 'api',
#        type  => 'boolean',
        name  => 'SuppressPrimary',
        value => 'false',
        );

    my $SuppressSecondary = SOAP::Data->new(
        prefix => 'api',
#        type  => 'boolean',
        name  => 'SuppressSecondary',
        value => 'false',
        );

    my $RecorderSettings = SOAP::Data->new(
        prefix => 'api',
#        type  => 'tns:RecorderSettings',
        name  => 'RecorderSettings',
        )->value( [ $RecorderId, $SuppressPrimary, $SuppressSecondary ] );

    my $recorderSettings = SOAP::Data->new(
        prefix => 'tns',
#        type  => 'api:ArrayOfRecorderSettings',
        name  => 'recorderSettings',
        )->value( \$RecorderSettings );

    my $som = $soap->ScheduleRecording(
        $auth,
        SOAP::Data->prefix('tns')->name( name => $args{'name'} ),
        SOAP::Data->prefix('tns')->name( folderId => $args{'folderId'} ),
        SOAP::Data->prefix('tns')->name( isBroadcast => $args{'isBroadcast'}?'true':'false' ),
        SOAP::Data->prefix('tns')->name( start => SOAP::Utils::format_datetime(gmtime($args{'start'})) ),
        SOAP::Data->prefix('tns')->name( end => SOAP::Utils::format_datetime(gmtime($args{'end'})) ),
        $recorderSettings,
        );

    return undef
        if $som->fault;

#TODO check ConflictsExist, ConflictingSessions

    my $result = $som->result->{'ScheduledRecordingResult'};

    return $result->{'SessionIDs'};
}


1;
