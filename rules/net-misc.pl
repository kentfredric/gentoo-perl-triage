#!perl
use strict;
use warnings;

package ruleset::net::misc;

use My::Ruleset::Register -category => 'net-misc';
use My::Ruleset::Utils qw/add_keywords add_use/;

match(
   qr/^(networkmanager)-\d/ => {
        testdeps => sub {
          add_use( '-glamor' => [ 'x11-base/xorg-server'] );
        }
      },
);


1;
