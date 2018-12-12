package ruleset::dev::db;

use strict;
use warnings;

use My::Ruleset::Register -category => 'dev-db';
use My::Ruleset::Utils qw/disable_feature/;

match(
  qr/^mysql-\d/ => {
    test => sub {

      # usersandbox unsupported
      disable_feature( 'usersandbox', [ 'dev-db/mysql' ] );
    },
  } );

match(
  qr/^percona-server-\d/ => {
    test => sub {

      # usersandbox unsupported
      disable_feature( 'usersandbox', [ 'dev-db/percona-server' ] );
    },
  } );


1;
