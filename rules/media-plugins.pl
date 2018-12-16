# vim: syntax=perl
#
package ruleset::media::plugins;

use My::Ruleset::Register -category => 'media-plugins';
use My::Ruleset::Utils qw/add_keywords add_use/;

match(
  qr/^vdr-lcr-\d/ => {
    install => sub {
      # https://bugs.gentoo.org/638348
      add_keywords('~amd64' => ['=media-video/vdr-2.2.0-r3']);
    }
  }
);

1;
