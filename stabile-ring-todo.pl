#!/usr/bin/env perl 
use strict;
use warnings;

use Data::Dump qw(pp);
open my $fh, '<', $ARGV[0] or die "Can't open $ARGV[0], $!";

while ( my $line = <$fh> ) {
  chomp $line;
  if ( $line =~ /^##/ ) {
    print "$line\n";
    next;
  }
  my ( $package, $status, $whiteboard ) = split /(?<=[^#])\s+#/, $line;
  next unless not defined $whiteboard or $whiteboard =~ /\A\s*\z/;
  print "$line\n"; 
}

