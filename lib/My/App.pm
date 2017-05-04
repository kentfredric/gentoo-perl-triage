use 5.006;    # our
use strict;
use warnings;

package My::App;

our $VERSION = '0.001000';

# ABSTRACT: Core Sync App

# AUTHORITY

use My::Utils qw( einfo ewarn );
use My::EixUtils qw( check_isolated write_todo );
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
    my @categories = do {
        open my $fh, '<', $_[0]->categories_file
          or die "can't read categories file";
        map { chomp; $_ } <$fh>;
    };
    my $match_cache = {};
    my $store_match = sub {
        my ( $cat, $pkg ) = @_;
        my $token = lc($cat) . '-' . lc( substr $pkg, 0, 1 );
        $match_cache->{$token} = {} unless exists $match_cache->{$token};
        $match_cache->{$token}->{ $cat . '/' . $pkg } = 1;
    };
    my $has_line = sub {
        my ($path) = @_;
        open my $fh, '<', $path or die "Can't open $path";
        while ( my $line = <$fh> ) {
            return 1 if $line =~ /inherit.*perl-(module|functions)/;
            return 1 if $line =~ m/dev-lang\/perl/;
            return 1 if $line =~ m/(dev-perl|perl-core)\//;
            return 1 if $line =~ m/virtual\/perl-*/;
        }
        return 0;
    };
  CATEGORY: for my $category (@categories) {
        next if $category eq 'dev-perl';
        next if $category eq 'perl-core';
        einfo("Doing category $category");
        opendir( my $dh, catfile( $_[0]->portage_root, $category ) );
      PKG: while ( my $dir = readdir $dh ) {
            next if $dir =~ /^..?$/;
            next if $dir =~ /^perl-/;
            next if $dir =~ /\./;
            next unless -d catfile( $_[0]->portage_root, $category, $dir );
            my $edh;
            if (
                not opendir(
                    $edh, catfile( $_[0]->portage_root, $category, $dir )
                )
              )
            {
                ewarn("Can't read $category/$dir");
                next PKG;
            }
          FIL: while ( my $filename = readdir $edh ) {
                next if $filename =~ /^..?$/;
                next unless $filename =~ /\.ebuild$/;
                if (
                    $has_line->(
                        catfile(
                            $_[0]->portage_root,
                            $category, $dir, $filename
                        )
                    )
                  )
                {
                    einfo("Matched $category/$dir");
                    $store_match->( $category, $dir );
                    next PKG;
                }
            }
        }
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

