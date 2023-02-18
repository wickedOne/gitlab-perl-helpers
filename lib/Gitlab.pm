#------------------------------------------------------------------------------
# File:         Gitlab.pm
#
# Description:  gitlab related functions.
#               for now only related to code owners file
#
# Revisions:    2023-01-20 - created
#               2023-02-18 - added GetPathsReference to be used with psalm.ppm
#------------------------------------------------------------------------------
package Gitlab;

use strict;
use warnings FATAL => 'all';

use Data::Dumper qw(Dumper);

#------------------------------------------------------------------------------
# Static properties
my %codeowners = ();
my %excludeHash = ();

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
            next unless /(\@[\w\/]{0,})$/;

            if (not exists $codeowners{$1}) {
                $codeowners{$1} = [];
            }

            push(@{$codeowners{$1}}, $path);
        }
    }

    close(FH);

    my $self = {
        owner      => $owner,
        codeowners => \%codeowners,
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
}GetPathsReference

#------------------------------------------------------------------------------
# Get owner paths reference
#
# Returns: reference to array of code owner paths
sub  {
    my $self = shift;

    return \@{$self->{codeowners}->{$self->{owner}}};
}

#------------------------------------------------------------------------------
# Get owner paths as infection filter
#
# Returns: comma separated string of code owner paths
sub GetCommaSeparatedPathList {
    my $self = shift;

    return join(",", $self->GetPaths());
}

1;