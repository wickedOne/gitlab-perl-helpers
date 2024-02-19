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
#               2024-02-18 - added support for default codeowners
#------------------------------------------------------------------------------
package GPH::Gitlab;

use strict;
use warnings FATAL => 'all';

use Data::Dumper;

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

    (exists($args{owner}) and exists($args{codeowners})) or die "$!";

    my $self = {
        owner      => $args{owner},
        file       => $args{codeowners},
        codeowners => undef,
        blacklist  => undef,
    };

    bless $self, $class;

    return $self->parseCodeowners(%args);
}

#------------------------------------------------------------------------------
# Parse codeowners file
#
# Inputs:  codeowners => (string) path to code owners file
#          excludes   => (array) paths to exclude
#
# Returns: reference to Gitlab object
sub parseCodeowners {
    my ($self, %args) = @_;
    my ($fh, %excludes, $default_owners);

    open $fh, '<', $args{codeowners} or die "unable to open codeowners file: $!";
    my @lines = <$fh>;
    close($fh);

    # build excludes hash for quick lookup
    if (exists($args{excludes})) {
        foreach my $item (@{$args{excludes}}) {
            $excludes{$item} = 1;
        }
    }

    foreach (@lines) {
        next if $_ =~ /^#.*/ or $_ =~ /^[\s]?$/;
        my $line = $self->sanitise($_);

        if ($line =~ /\]/) {
            $default_owners = ($line =~ /^[\^]?\[[^\]]+\](?:[\[0-9\]]{0,}) (.*)$/) ? $1 : undef;

            next;
        }

        my ($class_path, $owners) = split(/\s/, $line, 2);

        next if exists $excludes{$class_path};

        $owners = $owners || $default_owners;

        next unless defined $owners;

        foreach my $owner (split(/\s/, $owners)) {
            next unless $owner =~ /@/;
            if (not exists $self->{codeowners}{$owner}) {
                $self->{codeowners}{$owner} = [];
                $self->{blacklist}{$owner} = [];
            }

            push(@{$self->{codeowners}{$owner}}, $class_path);

            $self->blacklist($class_path);
        }
    }

    return ($self);
}

#------------------------------------------------------------------------------
# Check whether less specific path is already defined and add it to the blacklist
#
# Inputs:  class_path => (string) path to check and blacklist
#
# Returns: reference to Gitlab object
sub blacklist {
    my ($self, $class_path) = @_;

    foreach my $owner (keys %{$self->{codeowners}}) {
        foreach my $path (@{$self->{codeowners}{$owner}}) {
            if ($class_path =~ $path and $class_path ne $path) {
                push(@{$self->{blacklist}{$owner}}, $class_path);
            }
        }
    }

    return ($self);
}

#------------------------------------------------------------------------------
# Replace /**/* with a trailing forward slash
#
# Inputs:  line => (string) line to sanitise
#
# Returns: string
sub sanitise {
    my ($self, $line) = @_;

    my $pat = quotemeta('/**/* ');
    $line =~ s|$pat|/ |;

    return ($line);
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