#!perl
use strict;
use warnings;

use Data::Dump qw(pp);

my ( $master, $updates ) = @ARGV;

my %details;
#my %commented;

{
  open my $fh, '<', $master or die "Can't open $master, $!";


while ( my $line = <$fh> ) {
  chomp $line;
  if ( $line =~ /^##/ ) {
    next;
  }
  if ( $line =~ /\A\s*\z/ ) {
    next;
  }
  my ( $package, $status, $whiteboard ) = split /(?<=[^#])\s+#/, $line;

  my ( $real_package ) = $package;
  $real_package =~ s/^#//;

  #$commented{$real_package} = 0;
  #$commented{$real_package} = 1 if $package =~ m/\A#/;

  if ( defined $whiteboard and $whiteboard !~ /\A\s*\z/ ) {
    $details{$real_package} = $whiteboard;
  }
}
}
{
  open my $fh, '<', $updates or die "Can't open $updates, $!";
  while( my $line = <$fh> ) {
    chomp $line;
    if ( $line =~ /^##/ ) {
      print "$line\n";
      next;
    }
    if ( $line =~ /\A\s*\z/ ) {
      next;
    }
    my ( $package, $status, $whiteboard ) = split /(?<=[^#])\s+#/, $line;
    my ( $real_package ) = $package;
    $real_package =~ s/^#//;
 
    my $final_whiteboard;
    if ( defined $whiteboard and $whiteboard !~ /\A\s*\z/ ) {
      $final_whiteboard = $whiteboard;
    }
    if ( not defined $final_whiteboard and exists $details{$real_package} ) {
      $final_whiteboard = $details{$real_package};
    }
    my $display_pkg = $package;
    #if ( exists $commented{$real_package} ) {
    #    my $pfx = '#';
    #    $pfx = '' unless $commented{$real_package};
    #    $display_pkg = $pfx . $real_package;
    #}
    my $suffix = $status;
    $suffix =~ s/\s*$//;
    if ( defined $final_whiteboard ) {
      $final_whiteboard =~ s/\s*$//;
      $suffix = sprintf "%-7s #%s", $suffix, $final_whiteboard;
    }
    printf "%-80s #%s\n", $display_pkg, $suffix;
  
  }
}
