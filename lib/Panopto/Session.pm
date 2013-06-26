package Panopto::Session;

use strict;
use warnings;

use Panopto;

our $som;


sub new  {
    my $class = shift;
    my $self  = {};
    bless ($self, $class);

    return $self;
}


sub Load {
    my $self = shift;
    my $id = shift;

    use Panopto::Interface::SessionManagement;
    use SOAP::Lite; # +trace => qw(debug);

    my $soap = new Panopto::Interface::SessionManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    $som = $soap->GetSessionsById(
        Panopto->AuthenticationInfo,
        SOAP::Data->prefix('tns')->name(
            remoteRecorderIds => \SOAP::Data->value(
                SOAP::Data->prefix('arrays')->name( guid => $id ),
            )
        ) );

    return undef
        if $som->fault;

    return $som->result->{'Session'}->{'Id'};

}


sub State {
    my $self = shift;

    return $som->result->{'Session'}->{'State'};
}


1;
