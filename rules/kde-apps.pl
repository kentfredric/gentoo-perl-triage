# vim: syntax=perl
#
package ruleset::kde::apps;

use My::Ruleset::Register -category => 'kde-apps';
use My::Ruleset::Utils qw/add_keywords add_use/;

match(
    qr/^(kde-dev-scripts)-\d/ => {
        install => sub {
          # BACKTRACK => 100
          add_use('pcre16' => [ 
            '=dev-libs/libpcre2-10.30'
          ]);
          add_use('icu' => [
            '=dev-qt/qtcore-5.9.3'
          ]);
          add_use('xkb' => [
            '=x11-libs/libxcb-1.12-r2',
          ]);
          add_use('X' => [
            '=x11-libs/libxkbcommon-0.7.1',
          ]);

        },
    },
);

match(
    qr/^(marble)-\d/ => {
        testdeps => sub {
          add_use('xvfb -glamor' => [
              'x11-base/xorg-server'
          ]);
      }
   },
);


1;
