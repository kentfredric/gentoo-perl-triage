#!perl
use strict;
use warnings;

package ruleset::sci::libs;

use My::Ruleset::Register -category => 'sci-libs';
use My::Ruleset::Utils qw/add_keywords add_use/;

match(
   qr/^(plplot)-\d/ => {
        testdeps => sub {
          add_use( '-glamor' => [ 'x11-base/xorg-server'] );
          add_use( 'latex' => ['=sci-libs/plplot-5.12.0-r1']);
        }
      },
);


1;
