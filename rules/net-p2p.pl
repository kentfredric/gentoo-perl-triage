# vim: syntax=perl
#
package ruleset::net::p2p;

use My::Ruleset::Register -category => 'net-p2p';
use My::Ruleset::Utils qw/add_keywords add_use/;

match(
  qr/^eiskaltdcpp-2\.2\./ => {
    install => sub {
      add_use( 'json'   => [ 'net-p2p/eiskaltdcpp' ] );
    },
  },
);

1;
