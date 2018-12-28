# vim: syntax=perl
#
package ruleset::www::misc;

use My::Ruleset::Register -category => 'www-misc';
use My::Ruleset::Utils qw/add_keywords add_use/;

match(
  qr/^vdradmin-am-\d/ => {
    install => sub {
      # https://bugs.gentoo.org/638348
      add_keywords('~amd64' => ['=media-video/vdr-2.2.0-r3']);
    }
  }
);

match(
  qr/^xxv-\d/ => {
    install => sub {
      # https://bugs.gentoo.org/638348
      add_keywords('~amd64' => ['=media-video/vdr-2.2.0-r3']);
    }
  }
);

1;
