use 5.006;    # our
use strict;
use warnings;

package My::IndexFile;

our $VERSION = '0.001000';

# ABSTRACT: Keyword whiteboard state

# AUTHORITY

sub new {
    my $conf = ref $_[1] ? { %{ $_[1] } } : { @_[ 1 .. $#_ ] };
    my $self = bless $conf, $_[0];
    return $self;
}

sub stable {
  return ( $_[0]->{sections}->{stable} ||= [] );
}

sub testing {
  return ( $_[0]->{sections}->{testing} ||= [] );
}

sub data {
  return ( $_[0]->{data} ||= {} );
}

sub add_row {
  my ( $self, $family, $atom, $is_commented, $status, $whiteboard ) = @_;
  return if exists $self->{data}->{$atom};
  push @{ $self->{sections}->{$family} }, $atom;
  $status =~ s/\s*$//;
  $self->{data}->{$atom} = {
    is_commented => $is_commented,
    status       => $status,
    whiteboard   => $whiteboard,
  };
}

sub parse_file {
  my ( $class, $file ) = @_;
  open my $fh, '<', $file or die "Can't open $file, $!";
  my $section = 'stable';
  my $container = $class->new();
  while( my $line = <$fh> ) {
    chomp $line;
    if ( $line =~ /\A##\s*([^#:]+?)[#:\s]*\z/ ) {
      $section = $1;
      next;
    }
    if ( $line =~ /\A\s*\z/ ) {
      next;
    }
    my ( $package, $status, $whiteboard ) = split /(?<=[^#])\s+#/, $line;
    my ( $is_commented );
    if ( $package =~ s{\A#}{} ) {
      $is_commented = 1;
    }
    $container->add_row( $section, $package, $is_commented, $status, $whiteboard );
  }
  return $container;
}

sub to_string {
  my ($self) = @_;
  my $out = '';
  for my $section (qw( stable testing )) {
    $out .= sprintf qq[## %s:\n], $section;
    for my $item ( @{ $self->{sections}->{ $section } } ) {
      my $dval = $item;
      my $itemdata = $self->{data}->{$item};
      if ( $itemdata->{is_commented} ) {
        $dval = '#' . $dval;
      }
      $out .= sprintf "%-80s #", $dval;

      my $suffix = '';
      if ( defined $itemdata->{whiteboard} and length $itemdata->{whiteboard} ) {
          $suffix = $itemdata->{whiteboard};
      }
      my $status = '';
      if ( defined $itemdata->{status} and length $itemdata->{status} ) {
        $status = $itemdata->{status};
      }
      if ( length $suffix ) {
        $out .= sprintf "%-7s #%s", $status, $suffix;
      } else {
        $out .= $status;
      }
      $out .= "\n";
    }
  }
  return $out;
}
sub to_file {
  my ($self, $file) = @_;
  open my $fh, '>', $file or die "Can't open $file, $? $!";
  for my $section (qw( stable testing )) {
    $fh->printf(qq[## %s:\n], $section);
    for my $item ( @{ $self->{sections}->{ $section } } ) {
      my $dval = $item;
      my $itemdata = $self->{data}->{$item};
      if ( $itemdata->{is_commented} ) {
        $dval = '#' . $dval;
      }
      $fh->printf("%-80s #", $dval);

      my $suffix = '';
      if ( defined $itemdata->{whiteboard} and length $itemdata->{whiteboard} ) {
          $suffix = $itemdata->{whiteboard};
      }
      my $status = '';
      if ( defined $itemdata->{status} and length $itemdata->{status} ) {
        $status = $itemdata->{status};
      }
      if ( length $suffix ) {
        $fh->printf( "%-7s #%s", $status, $suffix );
      } else {
        $fh->print($status);
      }
      $fh->print("\n");
    }
  }
  return 1
}

sub inherit_whiteboard {
  my ( $self, $other ) = @_;
  for my $entry ( sort keys %{$other->{data}}) {
    next unless exists $self->{data}->{$entry};

    my $whiteboard = $other->{data}->{$entry}->{whiteboard};
    if ( defined $whiteboard and length $whiteboard ) {
      $self->{data}->{$entry}->{whiteboard} = $whiteboard;
    }
  }
}

1;

