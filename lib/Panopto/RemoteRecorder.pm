package Panopto::RemoteRecorder;

use strict;
use warnings;

use Panopto::Interface::RemoteRecorderManagement;
use SOAP::Lite +trace => qw(debug);


sub new  {
    my $class = shift;
    my $self  = {};
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
            SOAP::Data->prefix('tns')->name(
                remoteRecorderIds => \SOAP::Data->value(
                    SOAP::Data->prefix('ser')->name( guid => $id ),
                )
            ) );
    }
    else {
        # Query by ExternalId
        $som = $soap->GetRemoteRecordersByExternalId(
            Panopto->AuthenticationInfo,
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

    for my $key ( keys %{$som->result->{'RemoteRecorder'}} ) {
        $self->{$key} = $som->result->{'RemoteRecorder'}->{$key};
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


sub MachineIP {
    my $self = shift;

    return $self->{'MachineIP'};
}


sub Name {
    my $self = shift;

    return $self->{'Name'};
}


sub PreviewURL {
    my $self = shift;

    return $self->{'PreviewURL'};
}


sub SettingsURL {
    my $self = shift;

    return $self->{'SettingsURL'};
}


=head2 State

    returns the state of the recorder, as a string.

    Stopped         0   Not recording and no preview available
    Previewing      1   Not recording and a preview is available
    Recording       2   Currently recording
    Paused          3   Paused during a recording
    Faulted         4   An error has occured preventing recording
    Disconnected    5   Not connected to the network
    Blocked         6   The Panopto recorder (not the remote recorder) is
                        Running on the machine so the remote recorder can't run

=cut

sub State {
    my $self = shift;

    return $self->{'State'};
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

    return undef
        if $som->fault;

#TODO check ConflictsExist, ConflictingSessions

    my $result = $som->result->{'ScheduledRecordingResult'};

    return $result->{'SessionIDs'};
}


1;
