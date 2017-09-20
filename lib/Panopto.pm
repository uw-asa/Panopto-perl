package Panopto;


our (
    $userName,
    $serverName,
    $providerName,
    $applicationKey,
    );


sub import
{
    my $self = shift;
    my %args = (
        userName       => undef,
        serverName     => undef,
        providerName   => undef,
        applicationKey => undef,
        @_,
        );

    $self->SetUserName( $args{'userName'} )
        if $args{'userName'};
    $self->SetServerName( $args{'serverName'} )
        if $args{'serverName'};
    $self->SetProviderName( $args{'providerName'} )
        if $args{'providerName'};
    $self->SetApplicationKey( $args{'applicationKey'} )
        if $args{'applicationKey'};
    return $self;
}


sub UserName { return $userName; }

sub SetUserName {
    my $self = shift;
    return ( $userName = shift );
}


sub ServerName { return $serverName; }

sub SetServerName {
    my $self = shift;
    return ( $serverName = shift );
}


sub ProviderName { return $providerName; }

sub SetProviderName {
    my $self = shift;
    return ( $providerName = shift );
}


sub ApplicationKey { return $applicationKey; }

sub SetApplicationKey {
    my $self = shift;
    return ( $applicationKey = shift );
}


sub GetUserKey {
    my $userName = shift;

    return $providerName . '\\' . $userName;
}

sub GetAuthCode {
    my $payload = shift;

    use Digest::SHA qw(sha1_hex);

    my $signedPayload = $payload . '|' . $applicationKey;

    return uc( sha1_hex( $signedPayload ) );
}


sub AuthenticationInfo {
    my $self = shift;

    my $userKey = GetUserKey( $userName );
    my $authCode = GetAuthCode( $userKey . '@' . $serverName );

    if($providerName) {
        return SOAP::Data->new(
            prefix => 'tns',
            name   => 'auth',
            attr  => {xmlns => 'http://schemas.datacontract.org/2004/07/Panopto.Server.Services.PublicAPI.V40'},
            value  => \SOAP::Data->value(
                SOAP::Data->attr({xmlns => 'http://schemas.datacontract.org/2004/07/Panopto.Server.Services.PublicAPI.V40'})->name( AuthCode => $authCode ),
                SOAP::Data->attr({xmlns => 'http://schemas.datacontract.org/2004/07/Panopto.Server.Services.PublicAPI.V40'})->name( UserKey  => $userKey ),
            ) );
    } else {
        return SOAP::Data->new(
            prefix => 'tns',
            name   => 'auth',
            attr  => {xmlns => 'http://schemas.datacontract.org/2004/07/Panopto.Server.Services.PublicAPI.V40'},
            value  => \SOAP::Data->value(
                SOAP::Data->attr({xmlns => 'http://schemas.datacontract.org/2004/07/Panopto.Server.Services.PublicAPI.V40'})->name( Password => $applicationKey ),
                SOAP::Data->attr({xmlns => 'http://schemas.datacontract.org/2004/07/Panopto.Server.Services.PublicAPI.V40'})->name( UserKey  => $userName ),
            ) );
    }
}


sub SyncExternalUser {
    my $self = shift;
    my %args = (
        firstName => undef,
        lastName  => undef,
        email     => undef,
        EmailSessionNotifications => undef,
        externalGroupIds => undef,
        @_,
        );

    use Panopto::Interface::UserManagement;
    my $soap = new Panopto::Interface::UserManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my @externalGroupIds = @{$args{'externalGroupIds'}};
    map { s/&/&amp;/g } @externalGroupIds;

    my $som = $soap->SyncExternalUser(
        Panopto->AuthenticationInfo,
        SOAP::Data->prefix('tns')->name( firstName => $args{'firstName'} ),
        SOAP::Data->prefix('tns')->name( lastName  => $args{'lastName'} ),
        SOAP::Data->prefix('tns')->name( email     => $args{'email'} ),
        SOAP::Data->prefix('tns')->name(
            EmailSessionNotifications => $args{'EmailSessionNotifications'}?'true':'false' ),
        SOAP::Data->prefix('tns')->name('externalGroupIds')->attr({xmlns => 'http://schemas.microsoft.com/2003/10/Serialization/Arrays'})->value(
            \SOAP::Data->value(
                SOAP::Data->name( string => \@externalGroupIds ) ) ),
        );

    return ( 0, $som->fault->{ 'faultstring' } )
        if $som->fault;

    return ( 1, "User synchronized" );
}


sub SelfUserAccessDetails {
    my $self = shift;

    use Panopto::Interface::AccessManagement;
    my $soap = new Panopto::Interface::AccessManagement;

    $soap->autotype(0);
    $soap->want_som(1);

    my $som = $soap->GetSelfUserAccessDetails(
        Panopto->AuthenticationInfo,
        );

    return ( undef, $som->fault->{ 'faultstring' } )
        if $som->fault;

    return $som->result;
}


1;
