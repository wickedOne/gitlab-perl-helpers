#------------------------------------------------------------------------------
# File:         Gitlab.pm
#
# Description:  gitlab related functions.
#               for now only related to code owners file
#
# Revisions:    2023-01-20 - created
#------------------------------------------------------------------------------
package Gitlab;

use strict;
use warnings;

#------------------------------------------------------------------------------
# Static properties
# codeowners contains hash of all owners and their related paths
my %codeowners = ();

#------------------------------------------------------------------------------
# Construct new class
#
# Returns: reference to Gitlab object
sub new {
    my ($class, $path, $owner) = @_;

    open(FH, $path) or die "unable to open codeowners file, initialization failed $!";

    while (<FH>) {
        chomp $_;
        next unless /^.*\s\@[\w]+\/.*$/;

        my ($path, $owners) = split(' ', $_, 2);

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
# Returns: array of codeowner paths
sub GetPaths {
    my $self = shift;

    return @{$self->{codeowners}->{$self->{owner}}};
}

#------------------------------------------------------------------------------
# Get owner paths as infection filter
#
# Returns: comma separated string of codeowner paths
sub GetInfectionFilter {
    my $self = shift;

    return join(",", $self->GetPaths());
}

1;