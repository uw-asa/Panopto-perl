package Panopto::Sessions;

use strict;
use warnings;

use Panopto::Session;
use Panopto::Interface::SessionManagement;
use SOAP::Lite +trace => qw(debug);


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


sub List {
    my $self = shift;

    return undef unless $self->{'session_list'};

    return $self->{'session_list'};
}


1;
