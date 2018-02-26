# vim: syntax=perl
#
package ruleset::net::libs;

use My::Ruleset::Register -category => 'net-libs';
use My::Ruleset::Utils qw/add_keywords add_use/;

match(
    qr/^(webkit-gtk)-\d/ => {
        install => sub {
          add_use('-webgl -opengl -egl' => [
              'net-libs/webkit-gtk'
          ]);
          add_use('-opengl -egl' => [
              'media-libs/gst-plugins-bad'
          ]);
        },
    },
);

1;
