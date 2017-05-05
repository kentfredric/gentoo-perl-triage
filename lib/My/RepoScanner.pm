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

1;
