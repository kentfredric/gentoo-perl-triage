package ruleset::app::office;

use strict;
use warnings;

use My::Ruleset::Register -category => 'app-office';
use My::Ruleset::Utils qw/add_keywords add_use/;

match(
    qr/^gnucash-2\.(6|7)\./ => {
        install => sub {
            add_use( '-opengl -egl',
                [ '=media-libs/gst-plugins-bad-1.12.3', ] );
            add_use( '-opengl -webgl -egl', ['=net-libs/webkit-gtk-2.18.6'] );
        },
    }
);

1;
