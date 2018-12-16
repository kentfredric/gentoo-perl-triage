# vim: syntax=perl
#
package ruleset::kde::misc;

use My::Ruleset::Register -category => 'kde-misc';
use My::Ruleset::Utils qw/add_keywords add_use/;

match(
    qr/^(tellico)-\d/ => {
        testdeps => sub {
          add_use('xvfb -glamor' => [
              'x11-base/xorg-server'
          ]);
      }
   },
);


1;
