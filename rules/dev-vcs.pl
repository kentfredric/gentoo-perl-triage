#!perl
use strict;
use warnings;

package ruleset::dev::vcs;

use My::Ruleset::Register -category => 'dev-vcs';
use My::Ruleset::Utils qw/add_keywords add_use/;

match(
   qr/^(subversion)-\d/ => {
        testdeps => sub {
          add_use( '-dso' => [ 'dev-vcs/subversion'] );
        }
      },
);


1;
