use 5.006;    # our
use strict;
use warnings;

package My::App;

our $VERSION = '0.001000';

# ABSTRACT: Core Sync App

# AUTHORITY

use My::Utils qw( einfo ewarn );
use My::EixUtils qw( check_isolated write_todo );
use My::RepoScanner qw();
use File::Spec::Functions qw( catfile );

sub new {
    return bless { ref $_[1] ? %{ $_[1] } : @_[ 1 .. $#_ ] }, $_[0];
}

sub cmd_to_fn_name {
    my $copy = $_[1];
    $copy =~ s/-/_/g;
    return "cmd_" . $copy;
}

sub run {
    if ( not $_[1] ) {
        die "No command specified";
    }
    my $fn_name = $_[0]->cmd_to_fn_name( $_[1] );
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

sub portage_root {
    local $_ = $_[0]->{portage_root};
    defined or die "portage_root must be defined";
    length  or die "portage_root must have length";
    -d      or die "portage_root must be an existing dir";
    return $_;
}

sub categories_file {
    catfile( $_[0]->portage_root, qw( profiles categories ) );
}

sub cmd_sync_eix_in {
    $_[0]->cmd_sync_eix_perl_in;
    $_[0]->cmd_sync_eix_system_in;
}

sub cmd_sync_eix_perl_in {
    if ( not check_isolated ) {
        einfo("eix perl sync skipped");
        return;
    }
    for ( q[a] .. q[z], 0 .. 9 ) {
        write_todo( catfile( $_[0]->input_dir, 'dev-perl-' . $_ ),
            'dev-perl/' . $_ . '*' );
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
            wanted_category => sub { $_[0] !~ /^(dev-perl|perl-core)$/ },
            wanted_package => sub { $_[0] ne 'virtual' || $_[1] !~ /^perl-.*/ },
            wanted_file => sub { $_[2] =~ /\.ebuild$/ },
        }
    );
    my $match_cache = {};
    my $seen_cats   = {};
  ITEM: while ( $scanner->category ) {
        my $fn = catfile(
            $_[0]->portage_root, $scanner->category,
            $scanner->package,   $scanner->file
        );
        open my $fh, '<', $fn or die "Can't open $fn";
        $seen_cats->{ $scanner->category }++ < 1
          and warn $scanner->category . "\n";

        while ( my $line = <$fh> ) {
            if (   $line =~ /inherit.*perl-(module|functions)/
                or $line =~ m/dev-lang\/perl/
                or $line =~ m/(dev-perl|perl-core)\//
                or $line =~ m/virtual\/perl-*/ )
            {
                my $token = lc( $scanner->category ) . '-'
                  . lc( substr $scanner->package, 0, 1 );
                $match_cache->{$token}->{ $scanner->package } = 1;
                last ITEM unless $scanner->next_package;
                next ITEM;
            }
        }
        last unless $scanner->next_file;
    }
    for my $bucket ( sort keys %{$match_cache} ) {
        my (@out);
        my (@in) = sort keys %{ $match_cache->{$bucket} };
        einfo("Doing bucket $bucket: @in");
        if ( @in > 1 ) {
            push @out, shift @in;
            while (@in) {
                push @out, '-o', shift @in;
            }
            unshift @out, '-(';
            push @out, '-)';
        }
        else {
            @out = @in;
        }
        write_todo( catfile( $_[0]->input_dir, $bucket ), @out );
    }
}
1;

