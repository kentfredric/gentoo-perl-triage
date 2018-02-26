use 5.006;  # our
use strict;
use warnings;

package My::Ruleset::Register;

our $VERSION = '0.001000';

# ABSTRACT: Add rules for packages

# AUTHORITY

our %REGISTRY;

sub import {
  my $caller = caller;
  my ( $self, $args ) = ( $_[0], { ref $_[1] ? %{$_[1]} : @_[1..$#_] } );
  if ( not exists $args->{'-category'} ) {
    die "-category not specified";
  }
  my %stash;
  my $match = _mk_match( \%stash, q{} . $args->{'-category'} );
  no strict;
  *{ $caller . '::match' } = $match;
}

sub _mk_match {
  my ( $stash, $category ) = @_;
  return sub {
    my ( $matcher, $rules ) = @_;
    $REGISTRY{$category} = [] unless exists $REGISTRY{$category};
    push @{ $REGISTRY{$category} }, [ $matcher, $rules ];
  }
}

sub _find_matches {
  my ($self, $package ) = @_;
  my ( $cat, $pkg ); 
  if ( $package =~ qr{^[>=<~]*([^/]+?)[/](.*)$} ) {
    ( $cat, $pkg ) = ($1, $2);
  } else {
    warn "$package does not split\n";
    return;
  }
  if ( not exists $REGISTRY{ $cat } ) {
    warn "$cat not in \$REGISTRY\n";
    return;
  }
  return grep { $pkg =~ $_->[0]  } @{$REGISTRY{$cat}};
}

1;

