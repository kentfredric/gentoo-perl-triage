package ruleset::app::doc;

use strict;
use warnings;

use My::Ruleset::Register -category => 'app-doc';
use My::Ruleset::Utils qw/add_keywords add_use/;

match(
  qr/^kicad-doc-4\.0\.[56]$/ => {
    testdeps => sub {
      add_use( '-pdf', [ '=app-doc/kicad-doc-4.0.5', '=app-doc/kicad-doc-4.0.6' ] );
    },
  } );

match(
  qr/^kicad-doc-(4\.0\.7|5\.0\.0)(-r\d+|)$/ => {
    install => sub {

      # Required USE
      add_use( 'l10n_en', [ '=app-doc/kicad-doc-4.0.7', '=app-doc/kicad-doc-4.0.7-r1', '=app-doc/kicad-doc-5.0.0', ] );
    },
  } );

1;
