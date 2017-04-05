#!/usr/bin/env perl 

use strict;
use warnings;
use Data::Dump qw(pp);
use Term::ANSIColor qw( colored );

my ($atom) = @ARGV;
die unless length $atom;

my (@stable) = get_stable_package_names( $atom );
my (@all) = get_package_names( $atom );
my (@testing) = set_a_exclude_b( \@all, \@stable );

printf "## stable:\n%s\n", join qq[\n], format_todos(\@stable);
printf "## testing:\n%s\n", join qq[\n], format_todos(\@testing);

sub einfo {
  my $space = colored(['blue','bold'], '-' );
  printf STDERR "%s %s\n", colored(['bold','yellow'], '*' ), join q[ ], map { s/ /$space/gr } @_;
}

sub run_eix {
  my (@args) = @_;
  einfo("eix", @args );
  open my $fh, '-|', 'eix', @args or die "can't open eix";
  my @lines;
  while ( my $line = <$fh> ) {
    chomp $line;
    push @lines, $line;
  }
  return @lines;
}

sub get_stable_package_names {
  my ( @query ) = @_;
  get_package_names('--stable-' , @query );
}
sub get_package_names {
  my ( @query ) = @_;
  local $ENV{INST_FORMAT} = '<version>{wasstable}=stable{else}=unstable{} ';
  my @out;
  for my $line ( run_eix( '--pure-packages','--format','<category>/<name> <availableversions:INST_FORMAT>\n','--in-overlay','gentoo', @query ) ) {
    my ( $name, @rest ) = split / /, $line;
    push @out ,[ $name,  map { [ split /=/ ] } @rest ];
  }
  return @out;
}
sub set_a_exclude_b {
  my ( $set_a, $set_b ) = @_;
  my %set_b = map { $_->[0] => 1 } @{$set_b};
  return grep { !exists $set_b{$_->[0]} } @{$set_a};
}

sub format_todo {
  my ( $item ) = @_;
  my ( $atom, @versions ) = @{$item};
  my $first = 1;
  my @out;
  for my $item ( @versions ) {
    my $suffix = "";
    $suffix  = "testing" if $item->[1] ne 'stable';
    if ( $first ) {
      push @out, sprintf "%-80s #%s", '=' . $atom . '-' . $item->[0], $suffix;
      $first--;
      next;
    }
    push @out, sprintf "%-80s #%s", '#=' . $atom . '-' . $item->[0], $suffix;
  }
  return @out;
}

sub format_todos {
  my ( $items ) = @_;
  return map { format_todo($_) } @{$items};
}
