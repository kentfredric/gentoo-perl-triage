# vim: syntax=perl
#
package ruleset::xfce::base;

use My::Ruleset::Register -category => 'xfce-base';
use My::Ruleset::Utils qw/add_keywords add_use/;

match(
    qr/^(thunar)-\d/ => {
        testdeps => sub {
          add_use('-glamor xvfb' => [
              'x11-base/xorg-server'
          ]);
        },
    },
);

1;
