#------------------------------------------------------------------------------
# File:         Gitlab.pm
#
# Description:  gitlab related functions.
#               for now only related to code owners file
#
# Revisions:    2023-01-20 - created
#               2023-02-18 - added GetPathsReference to be used with psalm.pm
#               2023-12-23 - added blacklist for more specific path definition
#------------------------------------------------------------------------------
package Gitlab;

use strict;
use warnings FATAL => 'all';

#------------------------------------------------------------------------------
# Static properties
my %codeowners = ();
my %excludeHash = ();
my %blacklist = ();

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

    open(FH, $path) or die "unable to open codeowners file, initialization failed $!";

    # build excludes hash for quick lookup
    foreach my $item (@excludes) {
        $excludeHash{$item} = 1;
    }

    while (<FH>) {
        chomp $_;

        # skip if line does not contain @
        next unless /^.*\s\@[\w]+\/.*$/;

        my ($path, $owners) = split(' ', $_, 2);

        # skip if path is excluded
        next if exists $excludeHash{$path};

        foreach (split(' ', $owners)) {
            next unless /(\@[\w\-\/]{0,})$/;

            if (not exists $codeowners{$1}) {
                $codeowners{$1} = [];
                $blacklist{$1} = [];
            }

            push(@{$codeowners{$1}}, $path);
        }

        # check whether less specific path is already defined and add it to the blacklist
        while (my ($key, $value) = each %codeowners) {
            foreach my $defined (values $value) {
                if ($path =~ $defined and $path ne $defined) {
                    push(@{$blacklist{$key}}, $path);
                }
            }
        }
    }

    close(FH);

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
sub GetPaths {
    my $self = shift;

    return @{$self->{codeowners}->{$self->{owner}}};
}

#------------------------------------------------------------------------------
# Get blacklist paths
#
# Returns: array of blacklisted paths
sub GetBlacklistPaths {
    my $self = shift;

    return @{$self->{blacklist}->{$self->{owner}}};
}

#------------------------------------------------------------------------------
# Get owner paths reference
#
# Returns: reference to array of code owner paths
sub GetPathsReference {
    my $self = shift;

    return \@{$self->{codeowners}->{$self->{owner}}};
}

#------------------------------------------------------------------------------
# Get owner paths as comma separated path list
#
# Returns: comma separated string of code owner paths
sub GetCommaSeparatedPathList {
    my $self = shift;

    return join(",", $self->GetPaths());
}

#------------------------------------------------------------------------------
# Get comma separated path list from input array intersected by owner paths
#
# Inputs:  1) array paths to intersect with code owner paths
#
# Returns: comma separated string of paths
sub IntersectToCommaSeparatedPathList {
    my ($self, @paths) = @_;

    return join(",", $self->Intersect(@paths));
}

#------------------------------------------------------------------------------
# Intersect input array with owner paths, excluding blacklisted paths
#
# Inputs:  1) array paths to intersect with code owner paths
#
# Returns: array intersection result
sub Intersect {
    my ($self, @paths) = @_;
    my @diff = ();

    foreach my $path (@paths) {
        chomp $path;

        next unless $self->Match($path);
        next if $self->MatchBlacklist($path);

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
sub Match {
    my ($self, $path) = @_;

    foreach my $owner ($self->GetPaths()) {
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
sub MatchBlacklist {
    my ($self, $path) = @_;

    foreach my $owner ($self->GetBlacklistPaths()) {
        return 1 if $path =~ $owner;
    }

    return 0;
}

1;