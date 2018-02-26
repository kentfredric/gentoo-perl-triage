# vim: syntax=perl
#
package ruleset::media::gfx;

use My::Ruleset::Register -category => 'media-gfx';
use My::Ruleset::Utils qw/add_keywords add_use/;

match(
    qr/^(imagemagick)-\d/ => {
        install => sub {
          # test? ( corefonts truetype )
          add_use('corefonts truetype' => [
              'media-gfx/imagemagick'
          ]);
        },
    },
);

1;
