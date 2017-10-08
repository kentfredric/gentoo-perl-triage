#!perl
use strict;
use warnings;
use Path::Tiny qw( path );

infile: for my $filename ( @ARGV ) {
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
  my ( @siblings ) = grep { $_->basename ne path($open_fn)->basename } path($open_fn)->parent->children(qr/\.ebuild$/);
  for my $ebuild ( path($open_fn), @siblings ) {
    open my $fh, '<', $ebuild->absolute->stringify or next;
    while ( my $line = <$fh> ) {
      if ( $line =~ /perl-module/ ) {
        print "$pn\n"; next infile;
      }
      if ( $line =~ qr{dev-lang/perl} ) {
        print "$pn\n"; next infile;
      }
      if ( $line =~ qr{dev-perl} ) {
        print "$pn\n"; next infile;
      }
      if ( $line =~ qr{perl-core} ) {
        print "$pn\n"; next infile;
      }
      if ( $line =~ qr{virtual/perl-} ) {
        print "$pn\n"; next infile;
      }
    }
  }
}
