package Panopto;


our (
    $ServerName,
    $Instance,
    $ApplicationKey,
    $Username,
    $UserKey,
    $AuthCode,
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


1;
