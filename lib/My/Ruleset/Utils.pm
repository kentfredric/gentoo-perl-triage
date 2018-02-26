use 5.006;  # our
use strict;
use warnings;

package My::Ruleset::Utils;

our $VERSION = '0.001000';

# ABSTRACT: Tools for fixing portage

# AUTHORITY

use Exporter ();
*import = \&Exporter::import;

our @EXPORT_OK = qw/ add_keywords add_use add_unmask /;

sub add_keywords {
  if ( not ref $_[0] and ref $_[1] ) {
    spew_line("/etc/portage/package.accept_keywords/zzz-autounmask", "$_ $_[0]") for @{$_[1]};
  }
}

sub add_use {
  if ( not ref $_[0] and ref $_[1] ) {
    spew_line("/etc/portage/package.use/zzz-autounmask", "$_ $_[0]") for @{$_[1]};
  }
}

sub add_unmask {
  if ( ref $_[0] ) {
    spew_line("/etc/portage/package.unmask/zzz-autounmask", "$_") for @{$_[0]};
  }
}

sub spew_line {
  my ( $file, $line ) = @_;
  print qq[echo "$line" >> "$file"\n];
  unless ( $ENV{DRY_RUN} ) {
    open my $fh, ">>", $file or die "Can't open $file, $!";
    print {$fh} "$line\n" or die "Can't print to $file, $!";
    close $fh or warn "Error closing $file: $!";
  }
}

1;

