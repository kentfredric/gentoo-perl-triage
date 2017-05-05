use 5.006;    # our
use strict;
use warnings;

package My::RepoScanner;

our $VERSION = '0.001000';

# ABSTRACT: Gentoo portage repo scanner

# AUTHORITY

use File::Spec::Functions qw( catfile );

sub new {
    my $conf = ref $_[1] ? { %{ $_[1] } } : { @_[ 1 .. $#_ ] };
    die "root is required" unless exists $conf->{root};
    $_[0]->_check_root( $conf->{root} );
    my $self = bless $conf, $_[0];
    $self->{categories} = [ $self->_build_categories ];
    return $self;
}

sub _check_root {
    local $_ = $_[1];
    die "root must be defined"  unless defined;
    die "root must have length" unless length;
}

sub root { $_[0]->{root} }

sub _build_categories {
    my $file = catfile( $_[0]->root, qw( profiles categories ) );
    open my $fh, '<', $file or die "Can't read $file, $! $?";
    map { chomp; $_ } <$fh>;
}

our $DEPTH = 0;

sub next_category {
    local $DEPTH = $DEPTH + 1;
    # warn "$DEPTH > next_category\n";

    return unless @{ $_[0]->{categories} };
    my $next_category = shift @{ $_[0]->{categories} };
    delete $_[0]->{category_dh};
    return unless defined $next_category;
    if ( exists $_[0]->{wanted_category} ) {
        if ( $_[0]->{wanted_category}->($next_category) ) {
            return ( $_[0]->{category} = $next_category );
        }
        return $_[0]->next_category;
    }
    return ( $_[0]->{category} = $next_category );
}

sub next_package {
    local $DEPTH = $DEPTH + 1;

    #    warn "$DEPTH > next_package\n";

    my $category = $_[0]->category;
    return unless $category;
    delete $_[0]->{package_dh};
    delete $_[0]->{file};
    if ( not exists $_[0]->{category_dh} ) {
        my $catdir = catfile( $_[0]->root, $category );

        #        warn "$DEPTH opendir ($catdir)\n";
        if ( not opendir $_[0]->{category_dh}, $catdir ) {
            warn "Can't open $catdir: $? $!\n";
            return unless $_[0]->next_category;
            return $_[0]->next_package;
        }
    }
    my $next_package = readdir $_[0]->{category_dh};
    if ( not defined $next_package ) {

        #        warn "$DEPTH last readdir\n";
        return unless $_[0]->next_category;
        return $_[0]->next_package;
    }
    if ( $next_package =~ /^..?$/ ) {
#        warn "$DEPTH '.' ($next_package)\n";
        return $_[0]->next_package;
    }
    if ( !-d catfile( $_[0]->root, $category, $next_package ) ) {
        return $_[0]->next_package;
    }
    if ( exists $_[0]->{wanted_package} ) {
        if ( $_[0]->{wanted_package}->( $_[0]->category, $next_package ) ) {
            return ( $_[0]->{package} = $next_package );
        }

        #        warn "$DEPTH unwanted ($next_package)";
        return $_[0]->next_package;
    }
    return ( $_[0]->{package} = $next_package );
}

sub next_file {
    local $DEPTH = $DEPTH + 1;

    #   warn "$DEPTH > next_file\n";
    my $category = $_[0]->category;
    my $package  = $_[0]->package;
    return unless defined $category;
    if ( not exists $_[0]->{package_dh} ) {
        my $pkgdir = catfile( $_[0]->root, $category, $package );

        #   warn "$DEPTH opendir ($pkgdir)\n";
        if ( not opendir $_[0]->{package_dh}, $pkgdir ) {

            # warn "Can't open $pkgdir: $? $!\n";
            return unless $_[0]->next_package;
            return $_[0]->next_file;
        }
    }
    my $next_file = readdir $_[0]->{package_dh};
    if ( not defined $next_file ) {

        # warn "$DEPTH last readdir\n";
        return unless $_[0]->next_package;
        return $_[0]->next_file;
    }
    if ( $next_file =~ /^..?$/ ) {

        # warn "$DEPTH '.' ($next_file)\n";
        return $_[0]->next_file;
    }
    if ( !-f catfile( $_[0]->root, $category, $package, $next_file ) ) {

        # warn "$DEPTH non-file ($next_file)\n";
        return $_[0]->next_file;
    }
    if ( exists $_[0]->{wanted_file} ) {
        if ( $_[0]->{wanted_file}
            ->( $_[0]->category, $_[0]->package, $next_file ) )
        {
            return ( $_[0]->{file} = $next_file );
        }

        #    warn "$DEPTH unwanted ($next_file)\n";
        return $_[0]->next_file;
    }
    return ( $_[0]->{file} = $next_file );
}

sub category {
    return $_[0]->{category} if exists $_[0]->{category};
    return $_[0]->next_category;
}

sub package {
    return $_[0]->{package} if exists $_[0]->{package};
    return $_[0]->next_package;
}

sub file {
    return $_[0]->{file} if exists $_[0]->{file};
    return $_[0]->next_file;
}

sub tree_ebuild_iterator {
    my ( $self, %opts ) = @_;
    my $root = $self->root;
    my (@categories) = $self->categories;

    my (
        $category, $category_dh, $category_path,
        $package,  $package_dh,  $package_path,
    );
    return sub {

        while (1) {
            if ( not defined $category and @categories ) {
                my ($next_category) = shift @categories;
                warn "Get next category -> $next_category\n";

                if ( exists $opts{wanted_category} ) {
                    next unless $opts{wanted_category}->($next_category);
                }
                $category_path = catfile( $root, $next_category );
                if ( not opendir $category_dh, $category_path ) {
                    warn "Cant open category $next_category";
                    next;
                }
                $category = $next_category;
            }
            return if not defined $category;
            if ( not defined $package ) {
                my $next_package = readdir $category_dh;

                if ( not defined $next_package ) {
                    undef $category;
                    next;
                }
                next if $next_package =~ /^..?$/;
                $package_path = catfile( $root, $category, $next_package );
                next unless -d $package_path;
                if ( exists $opts{wanted_package} ) {
                    next
                      unless $opts{wanted_package}
                      ->( $category, $next_package );
                }

                if ( not opendir $package_dh, $package_path ) {
                    warn "Cant open package $category/$next_package";
                    next;
                }
                $package = $next_package;
            }

            my $filename = readdir($package_dh);
            if ( not defined $filename ) {
                undef $package;
                next;
            }
            if ( $filename =~ /^..?$/ ) {
                next;
            }
            if ( exists $opts{wanted_file} ) {
                next
                  unless $opts{wanted_file}->( $category, $package, $filename );
            }
            return [ $filename, catfile( $package_path, $filename ) ];
        }
        return;
    };

}

1;
