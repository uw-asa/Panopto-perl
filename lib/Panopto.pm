package Panopto;


our (
    $ServerName,
    $Instance,
    $ApplicationKey,
    $Username,
    $UserKey,
    $AuthCode,
    $AuthenticationInfo,
    );


sub ServerName { return $ServerName; }

sub SetServerName {
    my $self = shift;
    return ( $ServerName = shift );
}


sub Instance { return $Instance; }

sub SetInstance {
    my $self = shift;
    return ( $Instance = shift );
}


sub ApplicationKey { return $ApplicationKey; }

sub SetApplicationKey {
    my $self = shift;
    return ( $ApplicationKey = shift );
}


sub Username { return $Username; }

sub SetUsername {
    my $self = shift;
    return ( $Username = shift );
}


sub UserKey {
    $UserKey||= Panopto->Instance . '\\' . Panopto->Username;

    return $UserKey;
}


sub AuthCode {
    use Digest::SHA qw(sha1_hex);

    $AuthCode ||= uc( sha1_hex( Panopto->UserKey . '@' .
                                lc(Panopto->ServerName) . '|' .
                                lc(Panopto->ApplicationKey) ) );

    return $AuthCode;
}


sub AuthenticationInfo {
    $AuthenticationInfo ||= SOAP::Data->new(
        prefix => 'tns',
        name   => 'auth',
        value  => \SOAP::Data->value(
            SOAP::Data->prefix('api')->name( AuthCode => Panopto->AuthCode ),
            SOAP::Data->prefix('api')->name( UserKey  => Panopto->UserKey ),
        ) );

    return $AuthenticationInfo;
}


use Panopto::Interface::RemoteRecorderManagement;
use SOAP::Lite +trace => qw(debug);


sub ListRecorders {
    my $self = shift;
    my %args = (
        MaxNumberResults => 100,
        PageNumber       => 1,
        SortBy           => Name,
        @_,
        );

    my $soap = new Panopto::Interface::RemoteRecorderManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my $som = $soap->ListRecorders(
        Panopto->AuthenticationInfo,
        SOAP::Data->prefix('tns')->name(
            Pagination => \SOAP::Data->value(
                SOAP::Data->prefix('api')->name( MaxNumberResults => $args{'MaxNumberResults'} ),
                SOAP::Data->prefix('api')->name( PageNumber => $args{'PageNumber'} ),
            )
        ),
        SOAP::Data->prefix('tns')->name(
            SortBy => $args{'SortBy'},
        )
        );

    Abort($som->fault->{ 'faultstring' }) if $som->fault;

    return @{$som->result->{'PagedResults'}->{'RemoteRecorder'}};

}


1;
