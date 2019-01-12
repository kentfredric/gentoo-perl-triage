#!perl
use strict;
use warnings;

use File::Spec::Functions qw( rel2abs catfile );
use File::Basename qw( dirname );
use constant ROOT => rel2abs( dirname(__FILE__) );
use lib catfile( ROOT, 'lib' );
use constant RULE_DIR  => catfile( ROOT, 'rules' );

require My::Ruleset::Register;

my (%targets) = map { $_ => 1 } qw( install testdeps test );

if ( not $ARGV[0] or not exists $targets{$ARGV[0]} ){
  die "ARG[0] expected in <@{[sort keys %targets]}>";
}

if ( not $ARGV[1] or $ARGV[1] !~ qr/\// ) {
  die "ARG[1] expected atom";
}

opendir my $dh, RULE_DIR or die "cant open rule dir";
while( defined ( my $entry = readdir $dh )) {
  next if $entry =~ /^\.\.?$/;
  require (RULE_DIR() . '/' . $entry);
}

my ( @matches ) = My::Ruleset::Register->_find_matches($ARGV[1]);
if ( not @matches ) {
  warn "No conf fixes for $ARGV[1]\n";
  exit;
}

my ( @phase_matches ) = grep { exists $_->[1]->{$ARGV[0]} } @matches;

if ( not @phase_matches ) {
  warn "No conf fixes for $ARGV[1] in $ARGV[0]\n";
  exit;
}


for my $match ( @phase_matches ) {
  warn "$match->[0] $ARGV[0]\n";
  $match->[1]->{$ARGV[0]}->();
}
