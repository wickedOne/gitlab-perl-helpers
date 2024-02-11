#------------------------------------------------------------------------------
# File:         GPH::Infection.pm
#
# Description:  infection related functions.
#
# Revisions:    2023-03-27 - created
#               2024-02-10 - namespaced module, bugfixes and unit tests
#               2024-02-11 - constructor now requires named arguments
#------------------------------------------------------------------------------
package GPH::Infection;

use strict;
use warnings FATAL => 'all';

#------------------------------------------------------------------------------
# Construct new GPH::Infection class
#
# Inputs:  msi       => (string) minimum msi
#          covered   => (string) minimum covered msi
#          exit_code => int exit code for escapees, defaults to 8
#
# Returns: reference to GPH::Infection object
sub new {
    my ($class, %args) = @_;

    (exists($args{msi}) and exists($args{covered})) or die "$!";

    my $self = {
        msi     => $args{msi},
        covered => $args{covered},
        code    => $args{exit_code} || 8,
    };

    bless $self, $class;

    return $self;
}

#------------------------------------------------------------------------------
# Parse infection output and return appropriate exit code
#
# Returns: int
sub parse {
    my ($self) = @_;
    my $escapees = 0;
    my $msi = 0;
    my $covered = 0;

    while (<>) {
        if ($_ =~ '([\d]+) covered mutants were not detected') {
            $escapees = $1;
        }

        if ($_ =~ 'Mutation Score Indicator \(MSI\): ([\d]+)%') {
            $msi = $1;
        }

        if ($_ =~ 'Covered Code MSI: ([\d]+)%') {
            $covered = $1;
        }

        print $_;
    }

    if ($msi < $self->{'msi'} || $covered < $self->{'covered'}) {
        return 1;
    }

    if ($escapees != 0) {
        print "\n\n[warning] even though MSI is within allowed boundaries $escapees mutants were not detected. please improve your tests!\n";

        return $self->{'code'};
    }

    return 0;
}

1;