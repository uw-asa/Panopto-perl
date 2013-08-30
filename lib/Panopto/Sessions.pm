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
        SOAP::Data->prefix('tns')->name(
            sessionIds => \SOAP::Data->value(
                SOAP::Data->prefix('ser')->name( guid => $args{'guid'} )
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
        SOAP::Data->prefix('tns')->name(
            sessionExternalIds => \SOAP::Data->value(
                SOAP::Data->prefix('ser')->name( string => \@externalIds )
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


1;
