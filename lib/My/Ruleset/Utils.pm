use 5.006;  # our
use strict;
use warnings;

package My::Ruleset::Utils;

our $VERSION = '0.001000';

# ABSTRACT: Tools for fixing portage

# AUTHORITY

use Exporter ();
*import = \&Exporter::import;

our @EXPORT_OK = qw/ add_keywords add_use add_unmask disable_feature /;

# add_keywords( keyword, [ atom, atom, atom ])
sub add_keywords {
  if ( not ref $_[0] and ref $_[1] ) {
    spew_line("/etc/portage/package.accept_keywords/zzz-autounmask", "$_ $_[0]") for @{$_[1]};
  }
}

# add_use( useflag, [ atom, atom, atom ])
sub add_use {
  if ( not ref $_[0] and ref $_[1] ) {
    spew_line("/etc/portage/package.use/zzz-autounmask", "$_ $_[0]") for @{$_[1]};
  }
}

# add_unmask( [ atom, atom, atom ] )
sub add_unmask {
  if ( ref $_[0] ) {
    spew_line("/etc/portage/package.unmask/zzz-autounmask", "$_") for @{$_[0]};
  }
}

# disable_feature( name, [ atom, atom, atom] )
sub disable_feature {
  if ( not ref $_[0] and ref $_[1] ) {
    my $feature = $_[0];
    my $feature_name = "no-feature-$feature";
    my $feature_path = "/etc/portage/env/$feature_name";
    if ( !-e $feature_path  ) {
       spew_file($feature_path, <<"EOF");
export FEATURES="\${FEATURES} -$feature"
EOF
    }
    spew_line("/etc/portage/package.env/zzz-autounmask", "$_ $feature_name") for @{$_[1]};
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

sub spew_file {
  my ( $file, $content ) = @_;
  print qq[cat \$content > "$file"\n];
  unless ( $ENV{DRY_RUN} ) {
    open my $fh, ">", $file or die "Can't open $file, $!";
    print {$fh} "$content" or die "Can't print to $file, $!";
    close $fh or warn "Error closing $file, $!";
  }
}

1;

