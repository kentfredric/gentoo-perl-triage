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
    my ( $file, @query ) = @_;
    my $results = get_versions(@query);
    if ( not @{ $results->{stable} } and not @{ $results->{testing} } ) {
        einfo("No results for <@query>");
        return;
    }
    my $index = My::IndexFile->new();
    for my $stable ( @{ $results->{stable} } ) {
        my ( $atom, @versions ) = @{$stable};
        for my $record (@versions) {
            $index->add_row( 'stable', $record->{atom}, $record->{is_commented},
                $record->{status}, undef );
        }
    }
    for my $test ( @{ $results->{testing} } ) {
        my ( $atom, @versions ) = @{$test};
        for my $record (@versions) {
            $index->add_row( 'testing', $record->{atom},
                $record->{is_commented},
                $record->{status}, undef );
        }
    }

    einfo(
        sprintf "Writing todo stable: %s, testing: %s",
        scalar @{ $results->{stable} },
        scalar @{ $results->{testing} }
    );
    $index->to_file($file);
    einfo("done");
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

sub get_stable_package_names {
    my (@query) = @_;
    get_package_names( '--stable-', @query );
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
                atom   => ( '=' . $name . '-' . $version ),
                status => ( $status ne 'stable' ? 'testing' : '' ),
                is_commented => 1,
            };
            if ( ( $first > 0 ) and $status eq 'stable' ) {
              undef $record->{is_commented};
              $first--;
            }
            push @pairs_out, $record;
        }
        push @out, [ $name, @pairs_out ];
    }
    return @out;
}

sub set_a_exclude_b {
    my ( $set_a, $set_b ) = @_;
    my %set_b = map { $_->[0] => 1 } @{$set_b};
    return grep { !exists $set_b{ $_->[0] } } @{$set_a};
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
