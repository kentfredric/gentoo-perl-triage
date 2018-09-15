# vim: syntax=perl
#
package ruleset::app::eselect;

use My::Ruleset::Register -category => 'app-eselect';
use My::Ruleset::Utils qw/add_keywords add_use/;

match(
  qr/^eselect-gnome-shell-extensions-2018/ => {
    install => sub {
      add_use( 'systemd'   => [ 'virtual/udev' ] );
      add_use( 'systemd'   => [ 'virtual/libudev' ] );
      add_use( 'X systemd' => [ 'sys-apps/dbus' ] );
      add_use( 'python'    => [ 'dev-libs/libxml2' ] );
      add_use( 'X'         => [ 'media-libs/clutter' ] );
    },
  },
);

1;
