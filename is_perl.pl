#!perl
use strict;
use warnings;

for my $filename ( @ARGV ) {
  my $open_fn = $filename;
  $ENV{GIT_WORK_TREE} and $open_fn = $ENV{GIT_WORK_TREE} . $open_fn;

  next if not -e $open_fn;
  next if not $open_fn =~ /\.ebuild$/;
  if ( not $open_fn =~ qr{[^/]+/[^/]+/[^/]+[.]ebuild$} ) {
    warn "Don't look like these paths will load: '$open_fn' means what?";
    last;
  }

  my $pn = $filename;
  $pn =~ s/^/=/;
  $pn =~ s|/.*/|/|;
  $pn =~ s/[.]ebuild$//;
  if ( $pn =~ qr{dev-perl/} ) {
    print "$pn\n"; next;
  }
  if ( $pn =~ qr{(virtual/perl-.*|dev-lang/perl|perl-core/.*)} ) {
    next;
  }
  open my $fh, '<', $open_fn  or next;
  while ( my $line = <$fh> ) {
    if ( $line =~ /perl-module/ ) {
      print "$pn\n";  last
    }
    if ( $line =~ qr{dev-lang/perl} ) {
      print "$pn\n"; last;
    }
    if ( $line =~ qr{dev-perl} ) {
      print "$pn\n"; last;
    }
    if ( $line =~ qr{perl-core} ) {
      print "$pn\n"; last;
    }
    if ( $line =~ qr{virtual/perl-} ) {
      print "$pn\n"; last;
    }
  }


}
