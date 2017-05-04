#!perl
use strict;
use warnings;

use File::Spec::Functions qw( rel2abs catfile );
use File::Basename qw( dirname );
use constant ROOT => rel2abs( dirname(__FILE__) );
use lib catfile( ROOT, 'lib' );
use constant INDEX_DIR => catfile( ROOT, 'index' );
use constant INPUT_DIR => catfile( ROOT, 'index.in' );
use constant TODO_DIR  => catfile( ROOT, 'todo' );
use constant HOSTNAME  => qx/uname -n/;
use constant PORTAGE_ROOT => (
      exists $ENV{PORTAGE_ROOT}   ? $ENV{PORTAGE_ROOT}
    : HOSTNAME eq 'katipo2' ? '/nfs-mnt/amd64-root/usr/portage/'
    :                               '/usr/portage'
);

use My::App;

My::App->new(
    {
        root         => ROOT,
        index_dir    => INDEX_DIR,
        input_dir    => INPUT_DIR,
        todo_dir     => TODO_DIR,
        portage_root => PORTAGE_ROOT,
    }
)->run(@ARGV);

