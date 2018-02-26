# vim: syntax=perl
#
package ruleset::dev::perl;

use My::Ruleset::Register -category => 'dev-perl';
use My::Ruleset::Utils qw/add_keywords/;

match(
    qr/^(SQL-Translator|Specio|Params-ValidationCompiler)-\d/ => {
        install => sub {
            add_keywords(
                '~amd64' => [

                    # Perl 5.28 breaks <2.0.6
                    '=dev-perl/Role-Tiny-2.0.6',
                ]
            );

        }
    },
);

1;
