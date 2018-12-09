#!perl
use strict;
use warnings;

package ruleset::www::client;

use My::Ruleset::Register -category => 'www-client';
use My::Ruleset::Utils qw/add_keywords add_use/;

match(
   qr/^(netsurf)-\d/ => {
        install => sub {
          add_use( 'fbcon fbcon_frontend_x' => [ 'www-client/netsurf'] );
        }
      },
);


1;
