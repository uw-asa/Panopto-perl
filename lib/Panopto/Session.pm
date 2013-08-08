package Panopto::Session;

use strict;
use warnings;

use Panopto::Interface::SessionManagement;
use SOAP::Lite; # +trace => qw(debug);


=head2 new

    Construct a Panopto::Session object.

    Can use hash of properties to initialize

=cut

sub new  {
    my $class = shift;
    my $self  = { @_ };
    bless ($self, $class);

    return $self;
}


=head2 Load

    Load Panopto::Session object from the SOAP API

    takes sessionId (guid)

=cut

sub Load {
    my $self = shift;
    my %args = (
        guid => undef,
        @_,
        );

    return undef
        unless ref $args{'guid'} eq 'ARRAY';

# =~ /^\{?[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}\}?$/i;

    my $soap = new Panopto::Interface::SessionManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my $som;

    $som = $soap->GetSessionsById(
        Panopto->AuthenticationInfo,
        SOAP::Data->prefix('tns')->name(
            sessionIds => \SOAP::Data->value(
                SOAP::Data->prefix('ser')->name( guid => $args{'guid'} ),
            )
        ) );

    return undef
        if $som->fault;

    for my $key ( keys %{$som->result->{'Session'}} ) {
        $self->{$key} = $som->result->{'Session'}->{$key};
    }

    return $self->Id;
}


sub Duration {
    my $self = shift;

    return $self->{'Duration'};
}


sub Id {
    my $self = shift;

    return $self->{'Id'};
}


sub FolderName {
    my $self = shift;

    return $self->{'FolderName'};
}


sub IsBroadcast {
    my $self = shift;

    return $self->{'IsBroadcast'};
}


sub Name {
    my $self = shift;

    return $self->{'Name'};
}


=head StartTime

    The time the session started, or is scheduled to start, in UTC

=cut

sub StartTime {
    my $self = shift;

    return $self->{'StartTime'};
}


=head2 State

    The different states that a session can be in

    one of:
    Created       The session has just been created
    Scheduled     The session is scheduled to be recorded
    Recording     The session is currently recording
    Broadcasting  The session is currently broadcasting
    Processing    The session is done being recorded and is being processed by the server
    Complete      The session has been recorded and processed and can now be viewed

=cut

sub State {
    my $self = shift;

    return $self->{'State'};
}


sub ViewerUrl {
    my $self = shift;

    return $self->{'ViewerUrl'};
}


sub UpdateRecordingTime {
    my $self = shift;
    my %args = (
        start => undef, # timestamp
        end   => undef, # timestamp
        );

    my $soap = new Panopto::Interface::RemoteRecorderManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my $som = $soap->UpdateRecordingTime(
        Panopto->AuthenticationInfo,
        SOAP::Data->prefix('tns')->name( sessionId => $self->Id ),
        SOAP::Data->prefix('tns')->name(
            start => SOAP::Utils::format_datetime(gmtime($args{'start'})) ),
        SOAP::Data->prefix('tns')->name(
            end => SOAP::Utils::format_datetime(gmtime($args{'end'})) ),
        );

    return undef
        if $som->fault;

#TODO check ConflictsExist, ConflictingSessions

    my $result = $som->result->{'ScheduledRecordingResult'};

    return $result->{'SessionIDs'};
}


1;
