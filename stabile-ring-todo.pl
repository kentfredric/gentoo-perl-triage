#!/usr/bin/env perl 
use strict;
use warnings;

open my $fh, '<', $ARGV[0] or die "Can't open $ARGV[0], $!";

while ( my $line = <$fh> ) {
  chomp $line;
  if ( $line =~ /^##/ ) {
    next;
  }
  my ( $package, $status, $whiteboard ) = split /(?<=[^#])\s+#/, $line;
  next unless not defined $whiteboard or $whiteboard =~ /\A\s*\z/;
  $package =~ s/^#//;
  print "$package\n";
}

