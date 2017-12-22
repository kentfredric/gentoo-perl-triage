use 5.006;    # our
use strict;
use warnings;

package My::App;

our $VERSION = '0.001000';

# ABSTRACT: Core Sync App

# AUTHORITY

use My::Utils qw( einfo ewarn );
use My::EixUtils
  qw( check_isolated write_todo get_package_names partition_packages );
use My::RepoScanner qw();
use My::IndexFile qw();
use File::Spec::Functions qw( catfile );

sub new {
    return bless { ref $_[1] ? %{ $_[1] } : @_[ 1 .. $#_ ] }, $_[0];
}

sub _cmd_to_fn_name {
    my $copy = $_[1];
    $copy =~ s/-/_/g;
    return "cmd_" . $copy;
}

sub run {
    if ( not $_[1] ) {
        die "No command specified";
    }
    my $fn_name = $_[0]->_cmd_to_fn_name( $_[1] );
    if ( not $_[0]->can($fn_name) ) {
        die "No such command $_[1]";
    }
    $_[0]->can($fn_name)->( $_[0], @_[ 2 .. $#_ ] );
}

sub input_dir {
    local $_ = $_[0]->{input_dir};
    defined or die "input_dir must be defined";
    length  or die "input_dir must have length";
    -d      or die "input_dir must be an existing dir";
    return $_;
}

sub index_dir {
    local $_ = $_[0]->{index_dir};
    defined or die "index_dir must be defined";
    length  or die "index_dir must have length";
    -d      or die "index_dir must be an existing dir";
    return $_;
}

sub index_dir_files {
    opendir my $dfh, $_[0]->index_dir
      or die "Can't opendir to " . $_[0]->index_dir;
    my (@nodes);
    while ( my $file = readdir $dfh ) {
        next if $file =~ /\A..?\z/;
        push @nodes, $file;
    }
    return sort @nodes;
}

sub portage_root {
    local $_ = $_[0]->{portage_root};
    defined or die "portage_root must be defined";
    length  or die "portage_root must have length";
    -d      or die "portage_root must be an existing dir";
    return $_;
}

sub todo_dir {
    local $_ = $_[0]->{todo_dir};
    defined or die "todo_dir must be defined";
    length  or die "todo_dir must have length";
    -d      or die "todo_dir must be an existing dir";
    return $_;
}

sub categories_file {
    catfile( $_[0]->portage_root, qw( profiles categories ) );
}

sub cmd_all {
    $_[0]->cmd_sync_eix_in;
    $_[0]->cmd_merge_in;

    #$_[0]->cmd_update_todo;
    $_[0]->cmd_check_index;
}

sub cmd_sync_eix_in {
    $_[0]->cmd_sync_eix_perl_in;
    $_[0]->cmd_sync_eix_system_in;
}

sub cmd_normalize_index {
    opendir my $fh, $_[0]->index_dir;
    while ( my $file = readdir $fh ) {
        next if $file =~ /\A..?\z/;
        my $index =
          My::IndexFile->parse_file( catfile( $_[0]->index_dir, $file ) );
        $index->to_file( catfile( $_[0]->index_dir, $file ) );
    }
}

use Data::Dumper (qw( Dumper ));

sub cmd_stats_all {
    opendir my $fh, $_[0]->index_dir;
    my $stats = {};
    while ( my $file = readdir $fh ) {
        next if $file =~ /\A..?\z/;
        my $index =
          My::IndexFile->parse_file( catfile( $_[0]->index_dir, $file ) );
        $stats = $index->stats($stats);
    }

    my $tag_fmt = sub {
        my ($pairs) = @_;
        my @out;
        for my $pair ( @{$pairs} ) {
            next unless $pair->[1] > 0.01;
            my $fmt = shift @{$pair};
            push @out, sprintf $fmt, @{$pair};
        }
        if (@out) {
            return '(' . ( join ', ', map { sprintf "%15s", $_ } @out ) . ')';
        }
        return '';
    };
    printf "%d/%-6d -> %8.2f%% %s\n", $stats->{'all'}->{done},
      $stats->{'all'}->{count}, $stats->{'all'}->{pct},
      $tag_fmt->(
        [
            [ '%3d todo', $stats->{'all'}->{todo} ],
            [
                '%3d broken (%2.2f%%)', $stats->{'all'}->{broken},
                $stats->{'all'}->{broken_pct}
            ],
            [ '%3d to report', $stats->{'all'}->{to_report} ]
        ]
      );
}

sub cmd_stats {
    opendir my $fh, $_[0]->index_dir;
    my $stats = {};
    while ( my $file = readdir $fh ) {
        next if $file =~ /\A..?\z/;
        my $index =
          My::IndexFile->parse_file( catfile( $_[0]->index_dir, $file ) );
        $stats = $index->stats($stats);
    }

    my $tag_fmt = sub {
        my ($pairs) = @_;
        my @out;
        for my $pair ( @{$pairs} ) {
            next unless $pair->[1] > 0.01;
            my $fmt = shift @{$pair};
            push @out, sprintf $fmt, @{$pair};
        }
        if (@out) {
            return '(' . ( join ', ', map { sprintf "%15s", $_ } @out ) . ')';
        }
        return '';
    };
    for my $cat ( sort keys %{$stats} ) {
        printf "%8s: %6d/%-6d -> %8.2f%% %s\n", $cat,
          $stats->{$cat}->{done}, $stats->{$cat}->{count},
          $stats->{$cat}->{pct},
          $tag_fmt->(
            [
                [ '%3d todo', $stats->{$cat}->{todo} ],
                [
                    '%3d broken (%2.2f%%)', $stats->{$cat}->{broken},
                    $stats->{$cat}->{broken_pct}
                ],
                [ '%3d to report', $stats->{$cat}->{to_report} ]
            ]
          );

    }
}

sub cmd_stats_verbose {
    my (%buckets);
    opendir my $fh, $_[0]->index_dir;
    while ( my $file = readdir $fh ) {
        next if $file =~ /\A..?\z/;
        my $index =
          My::IndexFile->parse_file( catfile( $_[0]->index_dir, $file ) );
        my $stats = $index->stats( {} );
        my ( $bucket, $suffix, $letter ) = $file =~ /\A(.*)-(.*?)-(.)\z/;

        # next if $stats->{all}->{todo} eq '0';
        # next if $stats->{all}->{broken} > '0';
        # next if $stats->{all}->{pct} > 0;
        $bucket = "$bucket-$suffix";

        # $letter = "$suffix-$letter";
        my $rec = {
            letter     => $letter,
            count      => $stats->{all}->{count},
            todo       => $stats->{all}->{todo},
            pct        => $stats->{all}->{pct},
            broken     => $stats->{all}->{broken},
            to_report  => $stats->{all}->{to_report},
            broken_pct => $stats->{all}->{broken_pct},
        };
        $buckets{$bucket}->{count} =
          exists $buckets{$bucket}->{count}
          ? $buckets{$bucket}->{count} + $stats->{all}->{count}
          : $stats->{all}->{count};
        $buckets{$bucket}->{todo} =
          exists $buckets{$bucket}->{todo}
          ? $buckets{$bucket}->{todo} + $stats->{all}->{todo}
          : $stats->{all}->{todo};
        $buckets{$bucket}->{done} =
          exists $buckets{$bucket}->{done}
          ? $buckets{$bucket}->{done} + $stats->{all}->{done}
          : $stats->{all}->{done};

        $buckets{$bucket}->{broken} =
          exists $buckets{$bucket}->{broken}
          ? $buckets{$bucket}->{broken} + $stats->{all}->{broken}
          : $stats->{all}->{broken};

        $buckets{$bucket}->{to_report} =
          exists $buckets{$bucket}->{to_report}
          ? $buckets{$bucket}->{to_report} + $stats->{all}->{to_report}
          : $stats->{all}->{to_report};

        $buckets{$bucket}->{broken_pct} =
          ( ( $buckets{$bucket}->{broken} / $buckets{$bucket}->{count} ) *
              100.0 );

        $buckets{$bucket}->{pct} =
          ( ( $buckets{$bucket}->{done} / $buckets{$bucket}->{count} ) *
              100.0 );
        push @{ $buckets{$bucket}->{children} }, $rec;
    }

    my $tag_fmt = sub {
        my ($pairs) = @_;
        my @out;
        for my $pair ( @{$pairs} ) {
            next unless $pair->[1] > 0.01;
            my $fmt = shift @{$pair};
            push @out, sprintf $fmt, @{$pair};
        }
        if (@out) {
            return '(' . ( join ', ', map { sprintf "%15s", $_ } @out ) . ')';
        }
        return '';
    };
    for my $line (
        sort {
                 $b->{pct} <=> $a->{pct}
              or $a->{todo} <=> $b->{todo}
              or $a->{count} <=> $b->{count}
        } map { +{ category => $_, %{ $buckets{$_} } } } keys %buckets
      )
    {
        printf
          "%-30s : %4s : %8.2f%% %s\n",
          $line->{category}, $line->{count}, $line->{pct},
          $tag_fmt->(
            [
                [ '%3d todo', $line->{todo} ],
                [
                    '%3d broken (%2.2f%%)', $line->{broken}, $line->{broken_pct}
                ],
                [ '%3d to report', $line->{to_report} ]
            ]
          );

        for my $child (
            sort {
                     $a->{letter} cmp $b->{letter}
                  or $b->{pct} <=> $a->{pct}
                  or $a->{todo} <=> $b->{todo}
                  or $a->{count} <=> $b->{count}
            } @{ $line->{children} }
          )
        {
            printf
              " /%-28s : %4s : %8.2f%% %s\n",
              $child->{letter}, $child->{count}, $child->{pct},
              $tag_fmt->(
                [
                    [ '%3d todo', $child->{todo} ],
                    [
                        '%3d broken (%2.2f%%)', $child->{broken},
                        $child->{broken_pct}
                    ],
                    [ '%3d to report', $child->{to_report} ]
                ]
              );

        }

    }
}

sub cmd_stats_verbose_summary {
    my (%buckets);
    opendir my $fh, $_[0]->index_dir;
    while ( my $file = readdir $fh ) {
        next if $file =~ /\A..?\z/;
        my $index =
          My::IndexFile->parse_file( catfile( $_[0]->index_dir, $file ) );
        my $stats = $index->stats( {} );
        my ( $bucket, $suffix, $letter ) = $file =~ /\A(.*)-(.*?)-(.)\z/;

        # next if $stats->{all}->{todo} eq '0';
        # next if $stats->{all}->{broken} > '0';
        # next if $stats->{all}->{pct} > 0;
        $bucket = "$bucket-$suffix";

        # $letter = "$suffix-$letter";
        my $rec = {
            letter     => $letter,
            count      => $stats->{all}->{count},
            todo       => $stats->{all}->{todo},
            pct        => $stats->{all}->{pct},
            broken     => $stats->{all}->{broken},
            to_report  => $stats->{all}->{to_report},
            broken_pct => $stats->{all}->{broken_pct},
        };
        $buckets{$bucket}->{count} =
          exists $buckets{$bucket}->{count}
          ? $buckets{$bucket}->{count} + $stats->{all}->{count}
          : $stats->{all}->{count};
        $buckets{$bucket}->{todo} =
          exists $buckets{$bucket}->{todo}
          ? $buckets{$bucket}->{todo} + $stats->{all}->{todo}
          : $stats->{all}->{todo};
        $buckets{$bucket}->{done} =
          exists $buckets{$bucket}->{done}
          ? $buckets{$bucket}->{done} + $stats->{all}->{done}
          : $stats->{all}->{done};

        $buckets{$bucket}->{broken} =
          exists $buckets{$bucket}->{broken}
          ? $buckets{$bucket}->{broken} + $stats->{all}->{broken}
          : $stats->{all}->{broken};

        $buckets{$bucket}->{to_report} =
          exists $buckets{$bucket}->{to_report}
          ? $buckets{$bucket}->{to_report} + $stats->{all}->{to_report}
          : $stats->{all}->{to_report};

        $buckets{$bucket}->{broken_pct} =
          ( ( $buckets{$bucket}->{broken} / $buckets{$bucket}->{count} ) *
              100.0 );

        $buckets{$bucket}->{pct} =
          ( ( $buckets{$bucket}->{done} / $buckets{$bucket}->{count} ) *
              100.0 );
        push @{ $buckets{$bucket}->{children} }, $rec;
    }

    my $tag_fmt = sub {
        my ($pairs) = @_;
        my @out;
        for my $pair ( @{$pairs} ) {
            next unless $pair->[1] > 0.01;
            my $fmt = shift @{$pair};
            push @out, sprintf $fmt, @{$pair};
        }
        if (@out) {
            return '(' . ( join ', ', map { sprintf "%15s", $_ } @out ) . ')';
        }
        return '';
    };
    for my $line (
        sort { $a->{category} cmp $b->{category} }
        map { +{ category => $_, %{ $buckets{$_} } } } keys %buckets
      )
    {
        next
          unless ( $line->{todo} and $line->{todo} > 0 )
          or ( $line->{broken} and $line->{broken} > 0 )
          or ( $line->{to_report} and $line->{to_report} > 0 );
        printf
          "%-30s : %4s : %8.2f%% %s\n",
          $line->{category}, $line->{count}, $line->{pct},
          $tag_fmt->(
            [
                [ '%3d todo', $line->{todo} ],
                [
                    '%3d broken (%2.2f%%)', $line->{broken}, $line->{broken_pct}
                ],
                [ '%3d to report', $line->{to_report} ]
            ]
          );
    }

}

sub cmd_check_index {
    {
        opendir my $fh, $_[0]->index_dir;
        while ( my $file = readdir $fh ) {
            next if $file =~ /\A..?\z/;
            if ( !-f catfile( $_[0]->input_dir, $file ) ) {
                ewarn("No $file in input but is in index");
            }
        }
    }

    #    {
    #        opendir my $fh, $_[0]->todo_dir;
    #        while ( my $file = readdir $fh ) {
    #            next if $file =~ /\A..?\z/;
    #            if ( !-f catfile( $_[0]->input_dir, $file ) ) {
    #                ewarn("No $file in input, but is in todo");
    #            }
    #        }
    #    }
}

sub cmd_help {
    my (@commands) =
      sort map { s/^cmd_//; s/_/-/g; $_ } grep { $_ =~ /^cmd_/ } keys %{
        no strict 'refs';
        \%{ __PACKAGE__ . '::' }
      };
    print "$_\n" for @commands;
}

sub cmd_update_todo {
    die "Deprecated";
    opendir my $fh, $_[0]->index_dir;
    while ( my $file = readdir $fh ) {
        next if $file =~ /\A..?\z/;
        my $index =
          My::IndexFile->parse_file( catfile( $_[0]->index_dir, $file ) );

        my $todo_file = catfile( $_[0]->todo_dir, $file );
        $index->to_file_todo($todo_file);
    }
}

sub cmd_merge_in {
    opendir my $dh, $_[0]->input_dir;
    while ( my $file = readdir $dh ) {
        next if $file =~ /\A..?\z/;
        my $merge_data =
          My::IndexFile->parse_file( catfile( $_[0]->input_dir, $file ) );
        my $target = catfile( $_[0]->index_dir, $file );
        if ( -f $target ) {
            my $old_data = My::IndexFile->parse_file($target);
            $merge_data->inherit_whiteboard($old_data);
        }
        $merge_data->to_file($target);
    }
}

sub cmd_sync_eix_perl_in {
    if ( not check_isolated ) {
        einfo("eix perl sync skipped");
        return;
    }
    my $partitions = partition_packages( [ get_package_names('dev-perl/*') ] );
    for my $key ( sort keys %{$partitions} ) {
        write_todo( catfile( $_[0]->input_dir, $key ), $partitions->{$key} );
    }
}

sub cmd_sync_eix_system_in {
    if ( not check_isolated ) {
        einfo("eix system sync skipped");
        return;
    }
    my $scanner = My::RepoScanner->new(
        {
            root            => $_[0]->portage_root,
            wanted_category => sub {
                $_[0] !~ /\A(dev-perl|perl-core)\z/;
            },
            wanted_package => sub { $_[0] ne 'virtual' || $_[1] !~ /^perl-.*/ },
            wanted_file => sub { $_[2] =~ /\.ebuild$/ },
        }
    );
    my $match_cache = {};
    my $seen_cats   = {};
    my $seen_atoms  = {};
  ITEM: while ( $scanner->category ) {
        my $fn = catfile(
            $_[0]->portage_root, $scanner->category,
            $scanner->package,   $scanner->file
        );
        open my $fh, '<', $fn or die "Can't open $fn";

  #$seen_cats->{ $scanner->category }++ < 1  and warn $scanner->category . "\n";

        my $cat_pn = $scanner->category . '/' . $scanner->package;

        #$seen_atoms->{$cat_pn}++ < 1 and warn " >$cat_pn\n";
        while ( my $line = <$fh> ) {
            my $token = lc( $scanner->category ) . '-'
              . lc( substr $scanner->package, 0, 1 );

            if ( $line =~ /inherit.*perl-(app|module|functions)/ ) {
                warn "inherit in $cat_pn ( via " . $scanner->file . " )\n";
                $match_cache->{$cat_pn} = 1;
                last ITEM unless $scanner->next_package;
                next ITEM;
            }
            if ( $line =~ m/dev-lang\/perl/ ) {
                warn "dev-lang/perl in $cat_pn ( via "
                  . $scanner->file . " )\n";
                $match_cache->{$cat_pn} = 1;

                last ITEM unless $scanner->next_package;
                next ITEM;
            }
            if ( $line =~ m/(dev-perl\/\S*|perl-core\/\S*|virtual\/perl-\S*)/ )
            {
                warn "$1 in $cat_pn ( via " . $scanner->file . " )\n";
                $match_cache->{$cat_pn} = 1;

                last ITEM unless $scanner->next_package;

                next ITEM;
            }
        }
        last unless $scanner->next_file;
    }
    my (@all_matches) = ( sort keys %{$match_cache} );
    my (@all_results);
    while (@all_matches) {
        my ( @in, @out );
        while ( @in < 30 and @all_matches ) {
            push @in, shift @all_matches;
        }
        if ( @in > 1 ) {
            push @out, '-e', shift @in;
            while (@in) {
                push @out, '-o', '-e', shift @in;
            }
            unshift @out, '-(';
            push @out, '-)';
        }
        else {
            @out = ( '-e', @in );
        }
        push @all_results, get_package_names(@out);
    }

    my $partitions = partition_packages( \@all_results );
    for my $key ( sort keys %{$partitions} ) {
        write_todo( catfile( $_[0]->input_dir, $key ), $partitions->{$key} );
    }
}

sub cmd_gen_todolist {
    my (%buckets);
    for my $file ( $_[0]->index_dir_files ) {
        my $index =
          My::IndexFile->parse_file( catfile( $_[0]->index_dir, $file ) );
        my $stats = $index->stats( {} );
        my ( $bucket, $suffix, $letter ) = $file =~ /\A(.*)-(.*?)-(.)\z/;
        next if $stats->{all}->{todo} eq '0';
        for my $section (qw( stable testing )) {
            for my $item ( @{ $index->{sections}->{$section} } ) {
                my $dval     = $item;
                my $itemdata = $index->{data}->{$item};
                next
                  if defined $itemdata->{whiteboard}
                  and length $itemdata->{whiteboard};
                print( $dval . "\n" );
            }
        }
    }
}

my $idx_cache = {};

sub cmd_merge_status {
    my ( $self, $status_file ) = @_;
    local $?;
    if ( not defined $status_file or not -e $status_file ) {
        die
          "merge-status <status-file> --- <status-file> missing/non-existent ("
          . ( $? || "" ) . ")";
    }
    open my $fh, '<', $status_file or die "Can't open $status_file, $?";
    local $/ = "\n";
    while ( my $line = <$fh> ) {
        chomp $line;
        my ( $atom, ) = grep /\A=/, split /\s+/, $line;
        if ( not $atom ) {
            print "#$line\n";
            next;
        }
        $line =~ s{\Q$atom\E}{\e[32m$atom\e[0m}g;

        my ( $cat, $letter, $rest ) = $atom =~ qr{\A=([^/]+)/(.)(.+)\z};

        $letter = lc($letter);

        my $idx_file = catfile( $_[0]->index_dir, "$cat-$letter" );

        if ( not -e $idx_file ) {
            printf "%s: %s\n", $line, "\e[31m: NO IDX $cat-$letter\e[0m";
            next;
        }

        my $index =
            ( exists $idx_cache->{$idx_file} )
          ? ( $idx_cache->{$idx_file} )
          : ( $idx_cache->{$idx_file} = My::IndexFile->parse_file($idx_file) );

        if ( exists $index->{data}->{$atom} ) {
            my $line_color;

            if ( ( $index->{data}->{$atom}->{whiteboard} || '' ) eq '+' ) {
                if ( $line !~ /^pass/ ) {
                    $line_color = "\e[43;30;1m";
                }
                else {
                    $line_color = "\e[32m";
                }
            }
            else {
                if ( $line =~ /^pass/ ) {
                    $line_color = "\e[43;30;1m";
                }
                else {
                    $line_color = "\e[40;31;1m";
                }
            }

            printf "%s\n \e[33m%s-%s\e[0m -> %s #\e[36m%s\e[0m\n\n",
              "$line_color████▶\e[0m $line\e[0m $line_color◀████\e[0m",
              $cat, $letter, $atom, $index->{data}->{$atom}->{whiteboard} || '';
        }
        else {
            printf "%s: %s\n", $line, "\e[31m: NO DATA IN $cat-$letter\e[0m";
            next;
        }
    }
}

1;

