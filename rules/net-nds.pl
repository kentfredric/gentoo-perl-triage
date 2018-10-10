# vim: syntax=perl
#
package ruleset::net::nds;

use My::Ruleset::Register -category => 'net-nds';
use My::Ruleset::Utils qw/add_keywords add_use/;

match(
  qr/^(gosa-core)-2\.\d/ => {
    install => sub {
      add_use( 'mysqli' => [ 'dev-lang/php' ] );
    },
  },
);

1;
