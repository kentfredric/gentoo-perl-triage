# vim: syntax=perl
#
package ruleset::app::text;

use My::Ruleset::Register -category => 'app-text';
use My::Ruleset::Utils qw/add_keywords add_use/;

match(
    qr/^(xindy)-\d/ => {
        install => sub {
            add_keywords(
                '~amd64' => [

                    # Older versions broken on newer profiles
                    #  bug #638514
                    '=dev-lisp/clisp-2.49.90',
                ]
            );

        }
    },
);

match(
    qr/^(referencer)-\d/ => {
        install => sub {
            add_use("X" => [ 'dev-cpp/gtkmm', 'dev-cpp/cairomm' ]);
            add_use("cairo" => ['app-text/poppler']);
        }
    },
);


1;
