package ruleset::app::admin;

use strict;
use warnings;

use My::Ruleset::Register -category => 'app-admin';
use My::Ruleset::Utils qw/add_keywords add_use/;

match(
    qr/^diradm-2\.9\.7\.1$/ => {
        testdeps => sub {
            add_use( 'automount irixpasswd samba',
                ['=app-admin/diradm-2.9.7.1'] );
        },
    }
);

1;
