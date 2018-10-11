# vim: syntax=perl
#
package ruleset::x11::wm;

use My::Ruleset::Register -category => 'x11-wm';
use My::Ruleset::Utils qw/add_keywords add_use/;

match(
    qr/^(i3)-4\.1[45]/ => {
        testdeps => sub {
          add_use('xephyr kdrive' => [
              'x11-base/xorg-server'
          ]);
        },
    },
);

1;
