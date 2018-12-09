# vim: syntax=perl
#
package ruleset::gnome::base;

use My::Ruleset::Register -category => 'gnome-base';
use My::Ruleset::Utils qw/add_keywords add_use/;

match(
   qr/^(nautilus)-3\.20\./ => {
        install => sub {
            add_use( 'X'            => ['=media-libs/clutter-1.26.2-r1'] );
            add_use( 'dbus'         => ['=dev-libs/glib-2.52.3'] );
            add_use( 'X'            => ['=media-libs/clutter-gtk-1.8.4'] );
            add_use( 'X'            => ['=media-libs/clutter-gst-3.0.26']);
            add_use('gtk'           => ['=gnome-base/gvfs-1.32.2'] );
            add_use( '-opengl -egl' => ['>=media-libs/gst-plugins-bad-1.10'] );
            add_use( '-egl -opengl -webgl' => ['=net-libs/webkit-gtk-2.18.6'] );
        },
        testdeps => sub {
          add_use( '-glamor' => ['x11-base/xorg-server']);
        }
      },
);

match(
    qr/^(nautilus)-3\.24\./ => {
        install => sub {
            add_use( 'X'            => ['=media-libs/clutter-1.26.2-r1'] );
            add_use( 'dbus'         => ['=dev-libs/glib-2.52.3'] );
            add_use( 'X'            => ['=media-libs/clutter-gtk-1.8.4'] );
            add_use( 'X'            => ['=media-libs/clutter-gst-3.0.26']);
            add_use( 'gtk'          => ['=gnome-base/gvfs-1.32.2'] );
            add_use( '-opengl -egl' => ['>=media-libs/gst-plugins-bad-1.10'] );
            add_use( '-egl -opengl -webgl' => ['=net-libs/webkit-gtk-2.18.6'] );
        },
        testdeps => sub {
          add_use( '-glamor' => ['x11-base/xorg-server']);
        },
    },
);

1;
