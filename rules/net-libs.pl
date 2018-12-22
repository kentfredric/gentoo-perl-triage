# vim: syntax=perl
#
package ruleset::net::libs;

use My::Ruleset::Register -category => 'net-libs';
use My::Ruleset::Utils qw/add_keywords add_use/;

match(
    qr/^(webkit-gtk)-2\.22\.2/ => {
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

match(
    qr/^(webkit-gtk)-2\.22\.4/ => {
        install => sub {
          add_use('-webgl -opengl egl gles2' => [
              'net-libs/webkit-gtk'
          ]);
          add_use('-opengl -egl' => [
              'media-libs/gst-plugins-bad'
          ]);
          add_use('gles2' => [
              'media-libs/mesa',
              'media-libs/gst-plugins-base',
              'media-libs/gst-plugins-bad',
          ]);
        },
        testdeps => sub {
          add_use('-glamor xvfb' => ['x11-base/xorg-server']);
        },
    },
);


1;
