#!perl
use strict;
use warnings;

package ruleset::gnome::extra;

use My::Ruleset::Register -category => 'gnome-extra';
use My::Ruleset::Utils qw/add_keywords add_use/;

match(
   qr/^(nemo)-3\.8\./ => {
        testdeps => sub {
          add_use( '-glamor' => ['x11-base/xorg-server']);
        }
      },
);


1;
