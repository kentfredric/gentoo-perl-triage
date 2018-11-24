# vim: syntax=perl
#
package ruleset::www::apps;

use My::Ruleset::Register -category => 'www-apps';
use My::Ruleset::Utils qw/add_keywords add_use/;

match(
    qr/^(bugzilla)-\d/ => {
        install => sub {
            add_use( 'sqlite' => ['www-apps/bugzilla'] );
        },
    },
);

match(
    qr/^(rt)-\d/ => {
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

match(
  qr/^(mythweb)-\d/ => {
    install => sub {
      add_use( 'mysqli' => [ 'dev-lang/php' ] );
    }
  } );
1;
