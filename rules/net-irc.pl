# vim: syntax=perl
#
package ruleset::net::irc;

use My::Ruleset::Register -category => 'net-irc';
use My::Ruleset::Utils qw/add_keywords add_use/;

match(
    qr/^(epic5)-1\.1\.\d/ => {
        install => sub {
            add_use( 'ruby -ruby_targets_ruby22' => [ 'net-irc/epic5' ] );
        },
    },
);

1;
