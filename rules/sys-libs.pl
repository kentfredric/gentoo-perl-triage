package ruleset::sys::libs;

use strict;
use warnings;

use My::Ruleset::Register -category => 'sys-libs';
use My::Ruleset::Utils qw/disable_feature/;

match(
  qr/^libhugetlbfs-2\.2[01]$/ => {
    test => sub {

      # usersandbox unsupported
      disable_feature( 'userpriv', [ '=sys-libs/libhugetlbfs-2.20', '=sys-libs/libhugetlbfs-2.21' ] );
    },
  } );

1;
