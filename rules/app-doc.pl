package ruleset::app::doc;

use strict;
use warnings;

use My::Ruleset::Register -category => 'app-doc';
use My::Ruleset::Utils qw/add_keywords add_use/;

match(
    qr/^kicad-doc-4\.0\.[56]$/ => {
        testdeps => sub {
            add_use( '-pdf',
                [
                  '=app-doc/kicad-doc-4.0.5', 
                  '=app-doc/kicad-doc-4.0.6'
                ] );
        },
    }
);

1;
