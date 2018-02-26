# vim: syntax=perl
#
package ruleset::app::text;

use My::Ruleset::Register -category => 'app-text';
use My::Ruleset::Utils qw/add_keywords/;

match(
    qr/^(xindy)-\d/ => {
        install => sub {
            add_keywords(
                '~amd64' => [

                    # Older versions broken on newer profiles
                    #  bug #638514
                    '=dev-lisp/clisp-2.49.60',
                ]
            );

        }
    },
);

1;
