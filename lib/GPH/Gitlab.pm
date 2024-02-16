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
#               2024-02-11 - constructor now requires named arguments
#------------------------------------------------------------------------------
package GPH::Gitlab;

use strict;
use warnings FATAL => 'all';

#------------------------------------------------------------------------------
# Construct new class
#
# Inputs:  codeowners => (string) path to code owners file
#          owner      => (string) current code owner
#          excludes   => (array) paths to exclude
#
# Returns: reference to Gitlab object
sub new {
    my ($class, %args) = @_;
    my (%codeowners, %excludeHash, %blacklist);

    (exists($args{owner}) and exists($args{codeowners})) or die "$!";

    # build excludes hash for quick lookup
    if (exists($args{excludes})) {
        foreach my $item (@{$args{excludes}}) {
            $excludeHash{$item} = 1;
        }
    }

    open(my $fh, '<', $args{codeowners}) or die "unable to open codeowners file, initialization failed $!";

    my @lines = <$fh>;

    close($fh);

    for my $line (@lines) {

        # skip section line. default codeowners not yet supported
        next if $line =~  /[\[\]]/;
        # skip if line does not contain @
        next unless $line =~ /^.*\s\@[\w]+\/.*$/x;

        # replace /**/* with a trailing forward slash
        my $pat = quotemeta('/**/* ');
        $line =~ s|$pat|/ |;

        my ($class_path, $owners) = split(' ', $line, 2);

        # skip if path is excluded
        next if exists $excludeHash{$class_path};

        foreach (split(' ', $owners)) {
            next unless /(\@[\w\-\/]{0,})$/x;

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

    my $self = {
        owner      => $args{owner},
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