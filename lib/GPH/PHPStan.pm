#------------------------------------------------------------------------------
# File:         GPH::PHPStan.pm
#
# Description:  GPH::PHPStan related functions.
#
# Revisions:    2023-07-25 - created
#               2024-02-10 - namespaced module, bugfixes and unit tests
#               2024-02-11 - constructor now requires named arguments
#------------------------------------------------------------------------------

package GPH::PHPStan;

use strict;
use warnings FATAL => 'all';

#------------------------------------------------------------------------------
# Construct new class
#
# Inputs:  level              => (string) phpstan error level
#          paths              => (array) paths to analyse
#          ignoredDirectories => (array) paths to ignore
#          baseline           => (string) path to baseline file, defaults to undef
#          cacheDir           => (string) path to cache directory, defaults to 'var'
#          includes           => (array) includes
#          threads            => (int) threads, defaults to 4
#
# Returns: reference to GPH::PHPStan object
sub new {
    my ($class, %args) = @_;

    (exists($args{level}) and exists($args{paths})) or die "$!";

    # filter out empty arrays
    my $excludes = ((exists($args{ignoredDirectories}) and scalar(@{$args{ignoredDirectories}}) != 0) ? $args{ignoredDirectories} : undef);

    my $self = {
        level              => $args{level},
        paths              => $args{paths},
        ignoredDirectories => $excludes,
        baseline           => $args{baseline} || undef,
        cacheDir           => $args{cacheDir} || 'var',
        includes           => $args{includes} || undef,
        threads            => $args{threads} || 4
    };

    bless $self, $class;

    return $self;
}

#------------------------------------------------------------------------------
# Get config
#
# Returns: phpstan neon config file string
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