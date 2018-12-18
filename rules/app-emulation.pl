#!perl
use strict;
use warnings;

package ruleset::app::emulation;

use My::Ruleset::Register -category => 'app-emulation';
use My::Ruleset::Utils qw/add_keywords add_use/;

match(
   qr/^wine-(any|d3d9|staging|vanilla)-\d/ => {
        testdeps => sub {
          add_use('-glamor xvfb' => ['x11-base/xorg-server'] );
        }
      },
);
match(
   qr/^wine-d3d9-\d/ => {
        install => sub {
          # this is truely icky, you can't have d3d9 without
          # a specific video card driver ...
          add_use('d3d9 video_cards_nouveau' => ['media-libs/mesa'] );
        }
      },
);



