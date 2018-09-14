package ruleset::sys::apps;

use strict;
use warnings;

use My::Ruleset::Register -category => 'sys-apps';
use My::Ruleset::Utils qw/disable_feature/;

match(
    qr/^coreutils-\d/ => {
        test => sub {

            # usersandbox unsupported
            # https://bugs.gentoo.org/413621#c14
            disable_feature( 'usersandbox',
                ['sys-apps/coreutils'] );
        },
    }
);

1;
