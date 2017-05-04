use 5.006;    # our
use strict;
use warnings;

package My::Utils;

our $VERSION = '0.001000';

# ABSTRACT: Local utilty functions

# AUTHORITY

use Term::ANSIColor qw( colored );
use Exporter qw();

BEGIN {
    *import = \&Exporter::import;
}

our (@EXPORT_OK) = qw(
  einfo ewarn eerror
  einfo_cmd ewarn_cmd eerror_cmd
);

sub einfo {
    printf STDERR "%s %s\n", colored( [ 'bold', 'yellow' ], '*' ),
      join q[ ], @_;
}

sub ewarn {
    printf STDERR "%s %s\n", colored( [ 'bold', 'magenta' ], '*' ),
      join q[ ], @_;
}

sub eerror {
    printf STDERR "%s %s\n", colored( [ 'bold', 'red' ], '*' ), join q[ ], @_;
}

sub einfo_cmd {
    my $space = colored( [ 'blue', 'bold' ], '-' );
    printf STDERR "%s %s\n", colored( [ 'bold', 'yellow' ], '*' ),
      join q[ ], map { s/ /$space/gr } @_;
}

sub ewarn_cmd {
    my $space = colored( [ 'blue', 'bold' ], '-' );
    printf STDERR "%s %s\n", colored( [ 'bold', 'magenta' ], '*' ),
      join q[ ], map { s/ /$space/gr } @_;
}

sub eerror_cmd {
    my $space = colored( [ 'blue', 'bold' ], '-' );
    printf STDERR "%s %s\n", colored( [ 'bold', 'red' ], '*' ),
      join q[ ], map { s/ /$space/gr } @_;
}

1;

