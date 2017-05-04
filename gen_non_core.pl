#!perl
use strict;
use warnings;

use Path::Iterator::Rule;
use Path::Tiny;

my $root = path('/nfs-mnt/amd64-root/usr/portage/');
for my $category ( $root->child("profiles/categories")->lines_raw({ chomp => 1 }) ) {
  next if $category eq 'dev-perl';
  next if $category eq 'perl-core';
  warn "Doing $category\n";
  for my $dir ( $root->child($category)->children ) {
    next unless -d $dir;
    next if $category eq 'virtual' and $dir->basename =~ /^perl-/;
    for my $file ( $dir->children(qr/.ebuild$/) ) {
      if( has_perl_magic( $file ) ) {
        my $atom = $file->relative($root)->basename('.ebuild');
        my $pkg = $dir->basename;
        $atom =~ s{\Q/$pkg/\E}{};
        my $dep = sprintf "=%s/%s", $category, $atom;
        write_to( $category, $pkg, $dep );
       }
    }
  }
}

my %handles;

sub write_to {
  my ( $category, $pkg, $atom ) = @_;
  my $short = as_short( $category, $pkg );
  if ( not exists $handles{ $short } ) {
    printf "Creating index.in/$short\n";
    $handles{ $short } = path( 'index.in' , $short )->openw_raw;
  }
  $handles{$short}->printf("%-80s #\n", $atom);
}
sub as_short {
  my ( $category, $package ) = @_;
  return $category . '-' . lc(substr $package, 0, 1 );
}

sub has_perl_magic {
  my ( %todo ) = (
    'inherit_perl_module' => sub { $_ =~ /inherit.*perl-(module|functions)/  },
    'mention_dev_lang-perl' => sub { $_ =~ /dev-lang\/perl/ },
    'mention_perl_pkg' => sub { $_ =~ m{(perl-core/|dev-perl/virtual/perl-)} },
  );
  my $fh = path( shift )->openr_raw;
  while( my $line = <$fh> ) {
    return 1 if $line =~ /inherit.*perl-(module|functions)/;
    return 1 if $line =~ /dev-lang\/perl/;
    return 1 if $line =~  m{(perl-core/|dev-perl/virtual/perl-)};
  }
  return;
}


