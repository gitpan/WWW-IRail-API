package WWW::IRail::API;
BEGIN {
  $WWW::IRail::API::AUTHORITY = 'cpan:ESSELENS';
}
BEGIN {
  $WWW::IRail::API::VERSION = '0.001';
}
use strict;
use Carp qw/croak/;
use WWW::IRail::API::Stations;
use WWW::IRail::API::Connections;
use WWW::IRail::API::Liveboard;
use WWW::IRail::API::Vehicle;

use parent 'Exporter';
our @EXPORT = qw/&irail/;


sub new {
    my ($proto, $attr) = @_;
    my $class = ref $proto || $proto;
    my %attr = ( API => "v1", 
                 dataType => 'perl',
                 _client => 'LWP',
                 _cache => { stations => [], 
                             connections => {}, 
                             liveboards => {}, 
                             vehicles => {}, 
                             timestamps => {} 
                 }, 
                 ref $attr eq 'HASH' ? %{$attr} : @{$attr || []} );


    eval "require WWW::IRail::API::Client::$attr{_client}"; die $@ if $@;

    "WWW::IRail::API::Client::$attr{_client}"->can('process') 
        or croak "unable to initialize ". __PACKAGE__ ."::Client::$attr{_client} backend. ".
                 "Is the module loaded?";

    $attr{_client} = "WWW::IRail::API::Client::$attr{_client}"->new();


    return bless {%attr}, $class;
}


sub lookup_stations {
    my $self = shift;
    my %opts = ref $_[0] ? %{$_[0]} : @_;

    my $callback = ref $_[1] eq 'CODE' ? $_[1] : $opts{callback};

    my $http_req = WWW::IRail::API::Stations::make_request();
    my $http_res = $self->{_client}->process($http_req, $callback);
    my $response = WWW::IRail::API::Stations::parse_response( $http_res, 
                                                              $opts{dataType} || $self->{dataType},
                                                              sub { return /$opts{station}/i } );
    return $response;
}

sub lookup_connections { 
    my $self = shift;
    my %opts = ref $_[0] ? %{$_[0]} : @_;

    my $callback = ref $_[1] eq 'CODE' ? $_[1] : $opts{callback};

    my $http_req = WWW::IRail::API::Connections::make_request(\%opts);
    my $http_res = $self->{_client}->process($http_req, $callback);
    my $response = WWW::IRail::API::Connections::parse_response( $http_res,
                                                                 $opts{dataType} || $self->{dataType});
    return $response;
}

sub lookup_liveboard {
    my $self = shift;
    my %opts = ref $_[0] ? %{$_[0]} : @_;

    my $callback = ref $_[1] eq 'CODE' ? $_[1] : $opts{callback};

    my $http_req = WWW::IRail::API::Liveboard::make_request(\%opts);
    my $http_res = $self->{_client}->process($http_req, $callback);
    my $response = WWW::IRail::API::Liveboard::parse_response( $http_res, 
                                                               $opts{dataType} || $self->{dataType});
    return $response;
}

sub lookup_vehicle {
    my $self = shift;
    my %opts = ref $_[0] ? %{$_[0]} : @_;

    my $callback = ref $_[1] eq 'CODE' ? $_[1] : $opts{callback};

    my $http_req = WWW::IRail::API::Vehicle::make_request(\%opts);
    my $http_res = $self->{_client}->process($http_req, $callback);
    my $response = WWW::IRail::API::Vehicle::parse_response( $http_res, 
                                                             $opts{dataType} || $self->{dataType});
    return $response;
}

# function interface
sub irail {
    my %args = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;

    $args{dataType} ||= 'YAML'; 

    my $type = undef;

    $type = 'stations'    if $args{station};
    $type = 'connections' if $args{from} and $args{to};
    $type = 'liveboard'   if $args{from} xor $args{to};
    $type = 'vehicle'     if $args{vehicle};

    croak 'could not determine query type, did you specify the correct arguments?' unless $type;

    my $irail = new WWW::IRail::API;
    my $fn = 'lookup_'.$type;

    return $irail->$fn(\%args);
}


42;


=pod

=head1 VERSION

version 0.001

=head1 NAME

WWW::IRail::API - A wrapper for the iRail.be API

=head1 SYNOPSIS

    use WWW::IRail::API;
    use Data::Dumper;

    ## OO interface ############################################################################

    my $irail = new WWW::IRail::API( dataType => 'YAML' );
    my $trains_bxl_ost = $irail->lookup_connections(from => 'brussel noord', to => 'oostende');
    print Dumper($trains_bxl_ost);

    ## functional interface ####################################################################
    
    # YAML liveboard with trains departing from *Brussel Noord*
    print irail from => 'brussel noord' 

    # YAML connections of trains between *Brussel Noord* and *Oostende* for tomorrow at 14:00
    print irail from => 'brussel noord', to => 'oostende', date => 'tomorrow afternoon'

    # JSON station lookup of all stations matching qr/oost/
    print irail station => qr/oost/, dataType => 'json'

    # XML vehicle lookup
    print irail vehicle => 'BE.NMBS.CR2089', dataType => 'XML'

    # perl liveboard lookup
    my $board = irail from => 'brussel noord', dataType => 'perl';

=head1 DESCRIPTION

WWW::IRail::API is a set of modules which allow you to query the
L<http://dev.irail.be> API for Stations, Connections, Liveboard and Vehicle
data.

=head1 FEATURES

=head2 Multiple output formats

The returned results can be in either XML, JSON or YAML format. You can even
select between two flavours XML (xml, XML) to suit your taste. Ofcourse, if you
stay in perl, you can access the return object directly.

=head2 Isolated parsers based on HTTP::[qw/Request Response/]

The internal parsers consist of simply two subs. L<make_request()> which
takes in arbitrary query parameters and returns a L<HTTP::Request> object. And
L<parse_response()> which takes a L<HTTP::Response> and builds an object which
it then returns in the desired output format. 

This makes them isolated pieces of code and ideal for testing or plugging into
other HTTP aware systems. You can thus safely B<use WWW::IRail::API::Connection>
in your code without ever using or loading any other of our modules.

=head2 Support for sync or async pluggable clients

Clients take L<HTTP::Request> objects and B<process()> them by a request over
the wire. They then simply return the L<HTTP::Response> or they will call a callback with
the response as a first parameter. 

If you are going to write your own client, you only need to implement a process
sub which will be called with ($http_request, $callback) parameters giving you
the option to either return from your process call and ignore the callback or
call the callback and go async from there.

=head2 Natural data parsing

If date matches C</\w/> it will hand over parsing to L<DateTime::Format::Natural>. 
for example: date => 'friday at 6pm';

=head1 LIMITATIONS

=over 4

=item *

fetching the station list is an all or nothing operation, this should be cached

=item *

natural date parsing is in english only. It can also not parse 'friday afternoon' (yet)

=back

=head1 TODO

=over 4

=item *

implement caching

=item *

implement AE/Coro LWP client (in another module)

=back

=head1 EXAMPLES

Example you can run from the commandline to get you started quickly

    # install App::cpanminus the easy way 
    % curl -L http://cpanmin.us | sudo perl - --self-upgrade
    
    # install the WWW::IRail::API modules
    % cpanm -S WWW::IRail::API

    # run a onliner from the commandline interface
    % perl -MWWW::IRail::API -e 'print irail from => "brussel noord", to => "oostende", date => "next friday"

=head1 SEE ALSO

=over 4

=item *

L<LWP>

=item *

L<HTTP::Request>

=item *

L<HTTP::Response>

=item *

L<XML::Simple>

=item *

L<JSON::XS>

=item *

L<YAML>

=item *

L<DateTime::Format::Natural>

=back

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Tim Esselens <tim.esselens@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Tim Esselens.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

