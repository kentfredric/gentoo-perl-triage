package ruleset::app::accessibility;

use strict;
use warnings;

use My::Ruleset::Register -category => 'app-accessibility';
use My::Ruleset::Utils qw/add_keywords/;

match(
    qr/^festival-fi-20041119$/ => {
        install => sub {

            # GCC 7.2
            # https://bugs.gentoo.org/634224
            add_keywords( '~amd64',
                ['=app-accessibility/speech-tools-2.1-r4'] );
        },
    }
);

1;
