#!perl
use strict;
use warnings;

package ruleset::net::mail;

use My::Ruleset::Register -category => 'net-mail';
use My::Ruleset::Utils qw/add_keywords add_use/;

match(
   qr/^(notmuch)-0\.2[34567]/ => {
        testdeps => sub {
          add_use( 'emacs python valgrind' => ['net-mail/notmuch']);
        }
      },
);


1;
