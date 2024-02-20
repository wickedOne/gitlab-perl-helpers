package GPH::PHPStan;

use strict;
use warnings FATAL => 'all';

sub new {
    my ($class, %args) = @_;

    (exists($args{level}) and exists($args{paths})) or die "$!";

    # filter out empty arrays
    my $excludes = ((exists($args{ignored_directories}) and scalar(@{$args{ignored_directories}}) != 0) ? $args{ignored_directories} : undef);

    my $self = {
        level              => $args{level},
        paths              => $args{paths},
        ignoredDirectories => $excludes,
        baseline           => $args{baseline} || undef,
        cacheDir           => $args{cache_dir} || 'var',
        includes           => $args{includes} || undef,
        threads            => $args{threads} || 4
    };

    bless $self, $class;

    return $self;
}

sub getConfig {
    my $self = shift;
    my $config;

    if (defined $self->{baseline} || defined $self->{includes}) {
        $config = "includes:";

        if (defined $self->{baseline}) {
            $config .= "\n    - $self->{baseline}";
        }

        foreach my $line (@{$self->{includes}}) {
            $config .= "\n    - $line" if defined $line;
        }

        $config .= "\n\n";
    }

    $config .= "parameters:";
    $config .= "\n    level: $self->{level}";
    $config .= "\n    tmpDir: $self->{cacheDir}";
    $config .= "\n    parallel:\n        maximumNumberOfProcesses: $self->{threads}";

    $config .= "\n    paths:";

    foreach my $path (@{$self->{paths}}) {
        $config .= "\n        - $path";
    }

    if (defined $self->{ignoredDirectories}) {
        $config .= "\n    excludePaths:";

        foreach my $ignore (@{$self->{ignoredDirectories}}) {
            $config .= "\n        - $ignore" if defined $ignore;
        }
    }

    return ($config);
}

1;

__END__

=head1 NAME

GPH::PHPStan - generate custom configuration file for L<PHPStan|https://phpstan.org/>

=head1 SYNOPSIS

    use GPH::PHPStan;

    my $phpstan = GPH::PHPStan->new((
        level => 6,
        paths => ['src/', 'tests/'],
    ));

    print $phpstan->getConfig();

=head1 METHODS

=over 4

=item C<< -E<gt>new(%args) >>

the C<new> method creates a new GPH::PHPStan instance. it takes a hash of options, valid option keys include:

=over

=item level B<(required)>

phpstan analysis level

=item paths B<(required)>

paths to scan for analysis

=item ignored_directories

paths to ignore for analysis

=item baseline

path to baseline file

=item cache_dir

path to cache directory. defaults to 'var/'

=item includes

paths to neon files to include in the configuration

=item threads

maximum number of threads to use, defaults to 4.

=back

=item C<< -E<gt>getConfig() >>

returns configuration xml for PHPStan

=back

=head1 AUTHOR

the GPH::PHPStan module was written by wicliff wolda <wicliff.wolda@gmail.com>

=head1 COPYRIGHT AND LICENSE

this library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut