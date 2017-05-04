use 5.006;    # our
use strict;
use warnings;

package My::EixUtils;

our $VERSION = '0.001000';

# ABSTRACT: Eix query utils

# AUTHORITY

use feature qw( state );
use My::Utils qw( ewarn einfo_cmd einfo );
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
    my (@query)   = @_;
    einfo_cmd("get_versions", @query);
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
    if ( not @{$results->{stable}} and not @{$results->{testing}} ) {
      einfo("No results for <@query>");
      return;
    }
    einfo(sprintf "Writing todo stable: %s, testing: %s", scalar @{ $results->{stable} }, scalar @{ $results->{testing}});
    open my $fh, '>', $file or die "Can't open $file for writing";
    $fh->printf( "## stable:\n%s\n",
        join qq[\n], format_todos( $results->{stable} ) );
    $fh->printf( "## testing:\n%s\n",
        join qq[\n], format_todos( $results->{testing} ) );
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
        push @out, [ $name, map { [ split /=/ ] } @rest ];
    }
    return @out;
}

sub set_a_exclude_b {
    my ( $set_a, $set_b ) = @_;
    my %set_b = map { $_->[0] => 1 } @{$set_b};
    return grep { !exists $set_b{ $_->[0] } } @{$set_a};
}

sub format_todo {
    my ($item) = @_;
    my ( $atom, @versions ) = @{$item};
    my $first = 1;
    my @out;
    my $has_stable = scalar grep { $_->[1] eq 'stable' } @versions;
    for my $item (@versions) {
        my $suffix = "";
        $suffix = "testing" if $item->[1] ne 'stable';
        if ($first) {
            if ( $has_stable and $item->[1] ne 'stable' ) {
                push @out, sprintf "%-80s #%s",
                  '#=' . $atom . '-' . $item->[0], $suffix;
                next;
            }
            push @out, sprintf "%-80s #%s", '=' . $atom . '-' . $item->[0],
              $suffix;
            $first--;
            next;
        }
        push @out, sprintf "%-80s #%s", '#=' . $atom . '-' . $item->[0],
          $suffix;
    }
    return @out;
}

sub format_todos {
    my ($items) = @_;
    return map { format_todo($_) } @{$items};
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
        ewarn(
"System has multiple repositories <$_>, eix sources may be contaminated"
        );
        $is_isolated = 0;
        return !!$is_isolated;
    }
    return !!$is_isolated;
}

1;
