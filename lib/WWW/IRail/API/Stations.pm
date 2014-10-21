package WWW::IRail::API::Stations;
BEGIN {
  $WWW::IRail::API::Stations::AUTHORITY = 'cpan:ESSELENS';
}
BEGIN {
  $WWW::IRail::API::Stations::VERSION = '0.001';
}
use strict;
use Carp qw/croak/;
use Date::Format;
use DateTime::Format::Natural;
use HTTP::Request::Common;
use JSON::XS;
use XML::Simple;
use YAML qw/freeze/;


sub make_request {
    my %attr = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;

    my $url = 'http://dev.api.irail.be/stations/';

    my $req = new HTTP::Request(GET => $url);

    return $req;
}

sub parse_response {
    my ($http_response, $dataType, $filter) = @_;

    my $obj = XMLin($http_response->content,
        NoAttr => $dataType eq 'XML' ? 0 : 1,
        SuppressEmpty => '',
        NormaliseSpace => 2,
        ForceArray => [ 'station' ],
        GroupTags => { stations => 'station'},
        KeyAttr => [],
    );

    $obj->{station} = [grep { $filter->(lc $_) } @{$obj->{station}}] if ref $filter eq "CODE";

    for ($dataType) {
        /xml/i and return XMLout $obj, RootName=>'stations', GroupTags => { stations => 'station' };
        /json/i and return JSON::XS->new->ascii->pretty->allow_nonref->encode($obj);
        /yaml/i and return freeze $obj;
        /perl/i and return $obj;
    }

    return $obj; # default to perl

}

42;



=pod

=head1 VERSION

version 0.001

=head1 NAME

WWW::IRail::API::Stations - HTTP::Request builder and HTTP::Response parser for the IRail API Station data

=head1 SYNOPSIS

    make_request();

=head1 DESCRIPTION

This module builds a L<HTTP::Request> and has a parser for the
L<HTTP::Response>. It's up to you to transmit it over the wire. If don't want
to do that yourself, don't use this module directly and use L<WWW::IRail::API>
instead.

=head1 METHODS

=head2 make_request()

Has no arguments, requests the whole list of stations from the API

=head2 parse_response( I<{$http_response}>, I<"dataType">, I<filter()> )

parses the HTTP::Response you got back from the server, which if all went well contains XML.
That XML is then transformed into other data formats

=over 4

=item *

xml

=item *

XML

=item *

YAML

=item *

JSON

=item *

perl (default)

=back

=head3 example of output when dataType = 'xml'

=head1 METHODS

=begin xml

    <stations>
      <station>\'S GRAVENBRAKEL</station>
      <station>AALST</station>
      <station>AALST KERREBROEK</station>
    
      <!-- ... snip ... -->

    </stations>

=end xml

=head3 example of output when dataType = 'XML'

=begin xml

    <stations timestamp="1291047694" version="1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="stations.xsd">
      <station id="BE.NMBS.82" location="50.605075 4.137658" locationX="4.137658" locationY="50.605075">\'S GRAVENBRAKEL</station>
      <station id="BE.NMBS.1" location="50.943053 4.038586" locationX="4.038586" locationY="50.943053">AALST</station>
      <station id="BE.NMBS.2" location="50.948316 4.024773" locationX="4.024773" locationY="50.948316">AALST KERREBROEK</station>

      <!-- ... snip ... -->

    </stations>

=end xml

=head3 example of output when dataType = 'JSON'

=for json     { 
      "station" : [
        "\'S GRAVENBRAKEL",
        "AALST",
        "AALST KERREBROEK",
        "AALTER",
        // ...
      ]
    }

=head3 example of output when dataType = 'YAML'

=for YAML     station:
      - "\'S GRAVENBRAKEL"
      - AALST
      - AALST KERREBROEK
      - AALTER
      ...

=head3 example of output when dataType="perl" (default)

=for perl     $VAR1 = {
          'station' => [
                       '\'S GRAVENBRAKEL',
                       'AALST',
                       'AALST KERREBROEK',
                       'AALTER',
                       'AARLEN',
                       'AARSCHOT',
                        # ...
            ]
    };

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

