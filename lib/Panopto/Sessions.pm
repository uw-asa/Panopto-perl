package Panopto::Sessions;

use strict;
use warnings;

use Panopto::Session;


sub new  {
    my $class = shift;
    my $self  = {};
    bless ($self, $class);

    $self->Find(@_) if @_;

    return $self;
}


=head2 Find

    Load Panopto::Session objects from the server

    takes sessionIds (guid). Can be a single value or an array

=cut

sub Find {
    my $self = shift;
    my %args = (
        guid => undef,
        @_,
        );

    my $soap = new Panopto::Interface::SessionManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my $som;

    $som = $soap->GetSessionsById(
        Panopto->AuthenticationInfo,
        SOAP::Data->prefix('tns')->name('sessionIds')->attr({xmlns => 'http://schemas.microsoft.com/2003/10/Serialization/Arrays'})->value(
            \SOAP::Data->value(
                SOAP::Data->name( guid => $args{'guid'} )
            )
        ) );

    $self->{'session_list'} = undef;

    return undef
        if $som->fault;

    return undef
        unless $som->result->{'Session'};

    my @results;
    if ( ref $som->result->{'Session'} ne 'ARRAY' ) {
        push @results, $som->result->{'Session'};
    } else {
        push @results, @{$som->result->{'Session'}};
    }

    for my $result (@results) {
        my $Session = Panopto::Session->new(%$result);
        push @{$self->{'session_list'}}, $Session;
    }

    return scalar(@{$self->{'session_list'}});
}


sub FindByExternalId {
    my $self = shift;
    my @externalIds = @_;

    my $soap = new Panopto::Interface::SessionManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my $som = $soap->GetSessionsByExternalId(
        Panopto->AuthenticationInfo,
        SOAP::Data->prefix('tns')->name('sessionExternalIds')->attr({xmlns => 'http://schemas.microsoft.com/2003/10/Serialization/Arrays'})->value(
            \SOAP::Data->value(
                SOAP::Data->name( string => \@externalIds )
            )
        ) );

    $self->{'session_list'} = undef;

    return ( undef, $som->fault->{ 'faultstring' } )
        if $som->fault;

    return 0 unless $som->result && $som->result->{'Session'};

    my @results;
    if ( ref $som->result->{'Session'} ne 'ARRAY' ) {
        push @results, $som->result->{'Session'};
    } else {
        push @results, @{$som->result->{'Session'}};
    }

    for my $result (@results) {
        my $Session = Panopto::Session->new(%$result);
        push @{$self->{'session_list'}}, $Session;
    }

    return scalar(@{$self->{'session_list'}});
}


sub List {
    my $self = shift;

    return () unless $self->{'session_list'};

    return @{$self->{'session_list'}};
}


sub UpdateOwner {
    my $self = shift;
    my $userKey = shift;

    return ( undef, "no sessions to update" )
        unless $self->{'session_list'};

    return ( undef, "no UserKey to update" )
        unless $userKey;
    
    my $soap = new Panopto::Interface::SessionManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my $som = $soap->UpdateSessionOwner(
        Panopto->AuthenticationInfo,
        SOAP::Data->prefix('tns')->name('sessionIds')->attr({xmlns => 'http://schemas.microsoft.com/2003/10/Serialization/Arrays'})->value(
            \SOAP::Data->value(
                SOAP::Data->name( guid => map { $_->Id } @{$self->{'session_list'}} )
            ),
            SOAP::Data->prefix('tns')->name(
                newOwnerUserKey => $userKey ),
        ) );

    return ( undef, $som->fault->{ 'faultstring' } )
        if $som->fault;

    return 1;

}


sub Move {
    my $self = shift;
    my $folderId = shift;

    return ( undef, "no sessions to move" )
        unless $self->{'session_list'};

    return ( undef, "no folder to move to" )
        unless $folderId;
    
    my $soap = new Panopto::Interface::SessionManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my $som = $soap->MoveSessions(
        Panopto->AuthenticationInfo,
        SOAP::Data->prefix('tns')->name('sessionIds')->attr({xmlns => 'http://schemas.microsoft.com/2003/10/Serialization/Arrays'})->value(
            \SOAP::Data->value(
                SOAP::Data->name( guid => map { $_->Id } @{$self->{'session_list'}} )
            ),
            SOAP::Data->prefix('tns')->name(
                folderId => $folderId ),
        ) );

    return ( undef, $som->fault->{ 'faultstring' } )
        if $som->fault;

    return 1;

}


1;
