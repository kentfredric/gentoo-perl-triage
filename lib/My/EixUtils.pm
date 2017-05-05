use 5.006;    # our
use strict;
use warnings;

package My::EixUtils;

our $VERSION = '0.001000';

# ABSTRACT: Eix query utils

# AUTHORITY

use feature qw( state );
use My::Utils qw( ewarn einfo_cmd einfo );
use My::IndexFile qw();
use Exporter qw();

BEGIN {
    *import = \&Exporter::import;
}

our @EXPORT_OK = qw(
  check_isolated
  get_versions
  write_todo
  get_package_names
);

sub get_versions {
    my (@query) = @_;
    einfo_cmd( "get_versions", @query );
    my (@stable)  = get_stable_package_names(@query);
    my (@all)     = get_package_names(@query);
    my (@testing) = set_a_exclude_b( \@all, \@stable );
    return {
        stable  => \@stable,
        testing => \@testing,
    };
}

sub write_todo {
    my ( $file, $results ) = @_;
    if ( not @{ $results } ) {
        einfo("$file -> No results passed");
        return;
    }
    my $index = My::IndexFile->new();
    for my $record ( @{ $results } ) {
      my $grade = $record->{has_stable} ? 'stable' : 'testing';
      for my $version ( @{ $record->{versions} } ) {
          $index->add_row( $grade, $version->{atom}, $version->{is_commented},
            $version->{status}, undef );
      }
    }
    einfo(
        sprintf "Writing todo $file -> stable: %s, testing: %s",
        scalar @{ $index->{sections}->{stable} },
        scalar @{ $index->{sections}->{testing} }
    );
    $index->to_file($file);
}

sub run_eix {
    my (@args) = @_;
    einfo_cmd( "eix", @args );
    open my $fh, '-|', 'eix', @args or die "can't open eix";
    my @lines;
    while ( my $line = <$fh> ) {
        chomp $line;
        push @lines, $line;
    }
    close $fh;
    return @lines;
}

sub get_package_names {
    my (@query) = @_;
    local $ENV{INST_FORMAT} = '<version>{wasstable}=stable{else}=unstable{} ';
    my @out;
    for my $line (
        run_eix(
            '--pure-packages', '--format',
            '<category>/<name> <availableversions:INST_FORMAT>\n',
            '--in-overlay', 'gentoo', @query
        )
      )
    {
        my ( $name, @rest ) = split / /, $line;
        my (@pairs) = map { [ split /=/ ] } @rest;
        my (@pairs_out);
        my $first = 1;
        my $has_stable = scalar grep { $_->[1] eq 'stable' } @pairs;
        for my $item (@pairs) {
            my ( $version, $status ) = @{$item};
            my $record = {
                atom         => ( '=' . $name . '-' . $version ),
                status       => ( $status ne 'stable' ? 'testing' : '' ),
                is_commented => 1,
            };
            if ( ( $first > 0 ) and $status eq 'stable' ) {
                undef $record->{is_commented};
                $first--;
            }
            push @pairs_out, $record;
        }
        push @out,
          { name => $name, versions => \@pairs_out, has_stable => $has_stable };
    }
    return @out;
}

sub set_a_exclude_b {
    my ( $set_a, $set_b ) = @_;
    my %set_b = map { $_->{name} => 1 } @{$set_b};
    return grep { !exists $set_b{ $_->{name} } } @{$set_a};
}

sub check_isolated {
    state $is_isolated = undef;
    return !!$is_isolated if defined $is_isolated;
    my $content = do {
        open my $fh, '-|', 'portageq', 'get_repos', '/'
          or die "Can't query portageq";
        local $/;
        scalar <$fh>;
    };
    chomp $content;
    $is_isolated = 1;
    for ( grep { $_ ne 'gentoo' } split /\s+/, $content ) {
        ewarn(  "System has multiple repositories <$_>,"
              . " eix sources may be contaminated" );
        $is_isolated = 0;
        return !!$is_isolated;
    }
    return !!$is_isolated;
}

1;
