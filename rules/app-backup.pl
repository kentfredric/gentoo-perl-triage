package ruleset::app::backup;

use strict;
use warnings;

use My::Ruleset::Register -category => 'app-backup';
use My::Ruleset::Utils qw/add_use/;

match(
    qr/^bup-\d/ => {
        install => sub {

            # doc requires pandoc which requires GHC which is a compiletime
            # nightmare.
            add_use( '-doc', ['app-backup/bup'] );
        },
    }
);

1;
