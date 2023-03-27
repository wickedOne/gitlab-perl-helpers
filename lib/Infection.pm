#------------------------------------------------------------------------------
# File:         Infection.pm
#
# Description:  infection related functions.
#
# Revisions:    2023-03-27 - created
#------------------------------------------------------------------------------
package Infection;

use strict;
use warnings FATAL => 'all';

#------------------------------------------------------------------------------
# Construct new Infection class
#
# Inputs:  0) string minimum msi
#          1) string minimum covered msi
#          2) int exit code for escapees
#
# Returns: reference to Infection object
sub new {
    my ($class, $msi, $covered, $code) = @_;

    my $self = {
        msi     => $msi,
        covered => $covered,
        code    => $code || 8,
    };

    bless $self, $class;

    return $self;
}

#------------------------------------------------------------------------------
# Parse infection output and return appropriate exit code
#
# Returns: int
sub Parse {
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