#------------------------------------------------------------------------------
# File:         Gitlab.pm
#
# Description:  gitlab related functions.
#               for now only related to code owners file
#
# Revisions:    2023-01-20 - created
#               2023-02-18 - added GetPathsReference to be used with psalm.pm
#               2023-12-23 - added blacklist for more specific path definition
#               2024-02-10 - namespaced module, bugfixes and unit tests
#------------------------------------------------------------------------------
package GPH::Gitlab;

use strict;
use warnings FATAL => 'all';

use Data::Dumper;

#------------------------------------------------------------------------------
# Construct new class
#
# Inputs:  1) string path to code owners file
#          2) string current code owner
#          3) array paths to exclude
#
# Returns: reference to Gitlab object
sub new {
    my ($class, $path, $owner, @excludes) = @_;
    my (%codeowners, %excludeHash, %blacklist);

    open(my $fh, $path) or die "unable to open codeowners file, initialization failed $!";

    # build excludes hash for quick lookup
    foreach my $item (@excludes) {
        $excludeHash{$item} = 1;
    }

    while (<$fh>) {
        chomp $_;

        # skip if line does not contain @
        next unless /^.*\s\@[\w]+\/.*$/;

        my ($class_path, $owners) = split(' ', $_, 2);

        # skip if path is excluded
        next if exists $excludeHash{$class_path};

        foreach (split(' ', $owners)) {
            next unless /(\@[\w\-\/]{0,})$/;

            if (not exists $codeowners{$1}) {
                $codeowners{$1} = [];
                $blacklist{$1} = [];
            }

            push(@{$codeowners{$1}}, $class_path);
        }

        # check whether less specific path is already defined and add it to the blacklist
        foreach my $key (keys %codeowners) {
            foreach my $defined (@{$codeowners{$key}}) {
                if ($class_path =~ $defined and $class_path ne $defined) {
                    push(@{$blacklist{$key}}, $class_path);
                }
            }
        }
    }

    close($fh);

    my $self = {
        owner      => $owner,
        codeowners => \%codeowners,
        blacklist  => \%blacklist,
    };

    bless $self, $class;

    return $self;
}

#------------------------------------------------------------------------------
# Get owner paths
#
# Returns: array of code owner paths
sub getPaths {
    my $self = shift;

    return $self->{codeowners}->{$self->{owner}} || [];
}

#------------------------------------------------------------------------------
# Get blacklist paths
#
# Returns: array of blacklisted paths
sub getBlacklistPaths {
    my $self = shift;

    return $self->{blacklist}->{$self->{owner}} || [];
}

#------------------------------------------------------------------------------
# Get owner paths reference
#
# Returns: reference to array of code owner paths
sub getPathsReference {
    my $self = shift;

    return \$self->{codeowners}->{$self->{owner}};
}

#------------------------------------------------------------------------------
# Get owner paths as comma separated path list
#
# Returns: comma separated string of code owner paths
sub getCommaSeparatedPathList {
    my $self = shift;

    return join(",", @{$self->getPaths()});
}

#------------------------------------------------------------------------------
# Get comma separated path list from input array intersected by owner paths
#
# Inputs:  1) array paths to intersect with code owner paths
#
# Returns: comma separated string of paths
sub intersectCommaSeparatedPathList {
    my ($self, @paths) = @_;

    return join(",", $self->intersect(@paths));
}

#------------------------------------------------------------------------------
# Intersect input array with owner paths, excluding blacklisted paths
#
# Inputs:  1) array paths to intersect with code owner paths
#
# Returns: array intersection result
sub intersect {
    my ($self, @paths) = @_;
    my @diff;

    foreach my $path (@paths) {
        chomp $path;

        next unless $self->match($path);
        next if $self->matchBlacklist($path);

        push(@diff, $path);
    }

    return @diff;
}

#------------------------------------------------------------------------------
# Match input path with owner paths
#
# Inputs:  1) string path to match
#
# Returns: int
sub match {
    my ($self, $path) = @_;

    foreach my $owner (@{$self->getPaths()}) {
        return 1 if $path =~ $owner;
    }

    return 0;
}

#------------------------------------------------------------------------------
# Match input path with blacklisted paths
#
# Inputs:  1) string path to match
#
# Returns: int
sub matchBlacklist {
    my ($self, $path) = @_;

    foreach my $owner (@{$self->getBlacklistPaths()}) {
        return 1 if $path =~ $owner;
    }

    return 0;
}

1;