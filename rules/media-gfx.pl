# vim: syntax=perl
#
package ruleset::media::gfx;

use My::Ruleset::Register -category => 'media-gfx';
use My::Ruleset::Utils qw/add_keywords add_use/;

match(
  qr/^(imagemagick)-\d/ => {
    install => sub {

      # test? ( corefonts truetype )
      add_use( 'corefonts truetype' => [ 'media-gfx/imagemagick' ] );
    },
  },
);
match(
  qr/^feh-2\.(18|26|27)/ => {
    install => sub {

      # https://bugs.gentoo.org/474556
      add_use( 'jpeg png gif' => [ 'media-libs/imlib2' ] );
    },
  },
);

1;
