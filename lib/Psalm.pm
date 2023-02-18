#------------------------------------------------------------------------------
# File:         Psalm.pm
#
# Description:  psalm related functions.
#               for now only generate psalm config file
#
# Revisions:    2023-01-21 - created
#               2023-02-18 - ready for general usage
#------------------------------------------------------------------------------

package Psalm;

use strict;
use warnings FATAL => 'all';

#------------------------------------------------------------------------------
# Construct new class
#
# Inputs:  0) string psalm error level
#          1) string paths to analyse
#          2) string path to baseline file, defaults to undef
#          3) array ignored directories, defaults to undef
#          4) string path to cache directory, defaults to ./psalm
#
# Returns: reference to Psalm object
sub new {
    my ($class, $level, $paths, $baseline, $ignoredDirectories, $cacheDir) = @_;

    my $self = {
        level              => $level,
        paths              => $paths,
        ignoredDirectories => $ignoredDirectories || undef,
        baseline           => $baseline || undef,
        cacheDir           => $cacheDir || './psalm',
    };

    bless $self, $class;

    return $self;
}

#------------------------------------------------------------------------------
# Get config
#
# Returns: psalm.xml config file string
sub GetConfig {
    my $self = shift;

    my $config = "<?xml version=\"1.0\"?>
<psalm
    errorLevel=\"$self->{level}\"
    resolveFromConfigFile=\"true\"
    xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
    xmlns=\"https://getpsalm.org/schema/config\"
    xsi:schemaLocation=\"https://getpsalm.org/schema/config vendor/vimeo/psalm/config.xsd\"\n";

    if (defined $self->{baseline}) {
        $config .= "    errorBaseline=\"$self->{baseline}\"\n";
    }

    $config .= "    cacheDirectory=\"$self->{cacheDir}\"\n >\n  <projectFiles>";

    foreach my $path (@{$self->{paths}}) {
        $config .= "\n    <directory name=\"$path\" />";
    }

    if (defined $self->{ignoredDirectories}) {
        $config .= "\n    <ignoreFiles>";

        foreach my $path (@{$self->{ignoredDirectories}}) {
            $config .= "\n        <directory name=\"$path\" />";
        }

        $config .= "\n    </ignoreFiles>";
    }

    $config .= "\n  </projectFiles>\n</psalm>";

    return ($config);
}

1;