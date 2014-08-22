package Panopto::Session;

use strict;
use warnings;

use Panopto::Interface::SessionManagement;
#use SOAP::Lite +trace => qw(debug);


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
    my $guid = shift;
    $guid = shift if $guid eq 'guid';

    $guid = [ $guid ]
        unless ref $guid eq 'ARRAY';

# =~ /^\{?[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}\}?$/i;

    my $soap = new Panopto::Interface::SessionManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my $som;

    $som = $soap->GetSessionsById(
        Panopto->AuthenticationInfo,
        SOAP::Data->prefix('tns')->name('sessionIds')->attr({xmlns => 'http://schemas.microsoft.com/2003/10/Serialization/Arrays'})->value(
            \SOAP::Data->value(
                SOAP::Data->name( guid => $guid ),
            )
        ) );

    return undef
        if $som->fault;

    for my $key ( keys %{$som->result->{'Session'}} ) {
        $self->{$key} = defined($som->result->{'Session'}->{$key}) ? $som->result->{'Session'}->{$key} : '';
    }

    return $self->Id;
}


sub CreateScheduled {
    my $self = shift;
    my %args = (
        recorder    => undef, # obj
        name        => undef, # string
        folderId    => undef, # guid
        isBroadcast => undef, # boolean
        start       => undef, # timestamp
        end         => undef, # timestamp
        @_
        );

    my ($sessionId, $msg) = $args{'recorder'}->ScheduleRecording(%args);

    return (undef, $msg) unless $sessionId;

    return $self->Load($sessionId);
}


sub SetExternalId {
    my $self = shift;
    my $externalId = shift;

    my $soap = new Panopto::Interface::SessionManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my $som = $soap->UpdateSessionExternalId(
        Panopto->AuthenticationInfo,
        SOAP::Data->prefix('tns')->name( sessionId => $self->Id ),
        SOAP::Data->prefix('tns')->name( externalId => $externalId ),
    );

    return ( undef, $som->fault->{ 'faultstring' } )
        if $som->fault;

    return 1;
}


sub UpdateIsBroadcast {
    my $self = shift;
    my %args = (
        isBroadcast => undef, # boolean
        end   => undef, # timestamp
        @_,
        );

    my $soap = new Panopto::Interface::SessionManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my $som = $soap->UpdateSessionIsBroadcast(
        Panopto->AuthenticationInfo,
        SOAP::Data->prefix('tns')->name( sessionId => $self->Id ),
        SOAP::Data->prefix('tns')->name(
            isBroadcast => ( $args{'isBroadcast'} ? 'true' : 'false' ) ),
        );

    return undef
        if $som->fault;

    return;

    my $result = $som->result->{'ScheduledRecordingResult'};

    return $result->{'SessionIDs'};
}


sub SetName {
    my $self = shift;
    my $name = shift;

    my $soap = new Panopto::Interface::SessionManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my $som = $soap->UpdateSessionName(
        Panopto->AuthenticationInfo,
        SOAP::Data->prefix('tns')->name( sessionId => $self->Id ),
        SOAP::Data->prefix('tns')->name( name => $name ),
    );

    return ( undef, $som->fault->{ 'faultstring' } )
        if $som->fault;

    return 1;
}


sub SetDescription {
    my $self = shift;
    my $description = shift;

    my $soap = new Panopto::Interface::SessionManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my $som = $soap->UpdateSessionDescription(
        Panopto->AuthenticationInfo,
        SOAP::Data->prefix('tns')->name( sessionId => $self->Id ),
        SOAP::Data->prefix('tns')->name('description')->type('string')->value($description),
    );

    return ( undef, $som->fault->{ 'faultstring' } )
        if $som->fault;

    return 1;
}


sub UpdateRecordingTime {
    my $self = shift;
    my %args = (
        start => undef, # timestamp
        end   => undef, # timestamp
        @_,
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
