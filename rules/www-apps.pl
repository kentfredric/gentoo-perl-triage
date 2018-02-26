# vim: syntax=perl
#
package ruleset::www::apps;

use My::Ruleset::Register -category => 'www-apps';
use My::Ruleset::Utils qw/add_keywords add_use/;

match(
    qr/^(bugzilla)-\d/ => {
        install => sub {
          add_use('sqlite' => [             'www-apps/bugzilla'         ]);
        },
    },
);

1;
