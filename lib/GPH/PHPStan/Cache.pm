package GPH::PHPStan::Cache;

use strict;
use warnings FATAL => 'all';

sub new {
    my ($class, %args) = @_;

    my $self = {
        depth => $args{depth} || 1,
        relative => $args{relative} || undef,
        dependencies => undef,
    };

    bless $self, $class;

    return $self;
}

sub parseResultCache {
    my ($self, %args) = @_;
    my ($fh, $line, $key);
    my $in_array = 0;
    my $in_dependant = 0;
    my $in_dependent_files = 0;

    (exists($args{path})) or die "$!";

    open $fh, '<', $args{path} or die "unable to open cache file: $!";


    while ($line = <$fh>) {
        chomp $line;

        if ($line =~ /^\s*'dependencies'\s*=>\s*array\s*\($/) {
            $in_array = 1;
        } elsif ($in_array && $in_dependant == 0 && $line =~ /^\s*'([^']+)'\s*=>\s*$/) {
            $key = $self->relative($1);
            $in_dependant = 1;
        } elsif ($in_array && $in_dependant && $line =~ /^\s*'dependentFiles'\s*=>\s*$/) {
            $in_dependent_files = 1;
        } elsif ($in_array && $in_dependant && $in_dependent_files && $line =~ /^\s*[0-9]+\s*=>\s*'([^']+)',$/) {
            push(@{$self->{dependencies}{$key}}, $self->relative($1));
        } elsif ($in_array && $in_dependant && $in_dependent_files && $line =~ /^\s*\),\s*$/) {
            $in_dependent_files = 0;
        } elsif ($in_array && $in_dependant && $in_dependent_files == 0 && $line =~ /^\s*\),\s*$/) {
            $in_dependant = 0;
        }
    }

    close($fh);

    return($self);
}

sub relative {
    my ($self, $line) = @_;

    if (!defined $self->{relative}) {
        return($line);
    }

    return substr $line, index($line, $self->{relative});
};

sub dependencies {
    my ($self, @paths) = @_;
    my (@unique, @result);
    @result = @paths;

    for (my $i = 1; $i <= $self->{depth}; $i++) {
        push(@result, $self->iterate(@result));
    }

    @unique = do { my %seen; grep { !$seen{$_}++ } @result };

    return(@unique);
};

sub iterate {
    my ($self, @paths) = @_;
    my ($path, $dependant, @unique, @result);
    @result = @paths;

    foreach $path (@paths) {
        for $dependant (@{$self->{dependencies}{$path}}) {
            push(@result, $dependant);
        }
    }

    @unique = do { my %seen; grep { !$seen{$_}++ } @result };

    return(@unique);
};

1;

__END__

=head1 NAME

GPH::PHPStan::Cache - parse dependencies from phpstan's resultCache.php file.

=head1 SYNOPSIS

    use GPH::PHPStan::Cache;

    my $cache = GPH::PHPStan::Cache->new((depth => 1, relative => 'src/'));

=head1 METHODS

=over 4

=item C<< -E<gt>new(%args) >>

the C<new> method creates a new GPH::PHPUnit::Config. it takes a hash of options, valid option keys include:

=over

=item path B<(required)>

path to the C<resultCache.php> file

=item depth

depth of the dependency scan. defaults to 1. setting it to 2 for instance will retrieve the dependencies of the dependencies as well.

=item relative

when you want relative paths, to which directory should they be relative

=back

=item C<< -E<gt>parseResultCache(%config) >>

parses the cache file. it takes a hash of options, valid option keys include:

=over

=item path B<(required)>

path to the C<resultCache.php> file

=back

=item C<< -E<gt>relative($line) >> B<(internal)>

converts file path to relative path

=item C<< -E<gt>dependencies(@paths) >>

collects all dependencies for given C<@paths> and given C<$depth>

=item C<< -E<gt>iterate(@paths) >> B<(internal)>

collects all dependencies for given C<@paths>

=back

=head1 AUTHOR

the GPH::PHPUnit::Config module was written by wicliff wolda <wicliff.wolda@gmail.com>

=head1 COPYRIGHT AND LICENSE

this library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut