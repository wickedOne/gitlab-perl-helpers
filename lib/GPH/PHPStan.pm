#------------------------------------------------------------------------------
# File:         GPH::PHPStan.pm
#
# Description:  GPH::PHPStan related functions.
#
# Revisions:    2023-07-25 - created
#               2024-02-10 - namespaced module, bugfixes and unit tests
#------------------------------------------------------------------------------

package GPH::PHPStan;

use strict;
use warnings FATAL => 'all';

#------------------------------------------------------------------------------
# Construct new class
#
# Inputs:  0) string phpstan error level
#          1) array paths to analyse
#          2) array paths to ignore
#          3) string path to baseline file, defaults to undef
#          4) array ignored directories
#          5) string path to cache directory, defaults to 'var'
#          6) array includes
#          6) int threads, defaults to 4
#
# Returns: reference to GPH::PHPStan object
sub new {
    my ($class, $level, $paths, $baseline, $ignoredDirectories, $cacheDir, $includes, $threads) = @_;

    my $self = {
        level              => $level,
        paths              => $paths,
        ignoredDirectories => $ignoredDirectories || undef,
        baseline           => $baseline || undef,
        cacheDir           => $cacheDir || 'var',
        includes           => $includes || undef,
        threads            => $threads || 4,
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

    my $config = "includes:";

    if (defined $self->{baseline}) {
        $config .= "\n    - $self->{baseline}";
    }

    foreach my $include (@{$self->{includes}}) {
        $config .= "\n    - $include";
    }

    $config .= "\n\nparameters:";
    $config .= "\n    level: $self->{level}";
    $config .= "\n    tmpDir: $self->{cacheDir}";
    $config .= "\n    parallel:\n        maximumNumberOfProcesses: $self->{threads}";

    $config .= "\n    paths:";
    foreach my $path (@{$self->{paths}}) {
        $config .= "\n        - $path";
    }

    if (@{$self->{ignoredDirectories}}) {
        $config .= "\n    excludePaths:";
        foreach my $path (@{$self->{ignoredDirectories}}) {
            $config .= "\n        - $path";
        }
    }

    return ($config);
}

1;