#------------------------------------------------------------------------------
# File:         Stat.pm
#
# Description:  PHPUnit coverage statistics object
#
# Revisions:    2024-02-10 - created
#------------------------------------------------------------------------------
package GPH::PHPUnit::Stat;

use strict;
use warnings FATAL => 'all';

#------------------------------------------------------------------------------
# Construct new GPH::PHPUnit::Stat class
#
# Returns: reference to GPH::PHPUnit::Stat object
sub new {
    my ($proto) = @_;

    return bless {
        'covered' => 0,
        'total'   => 0,
    }, $proto;
};

#------------------------------------------------------------------------------
# Add covered and total count
#
# Inputs:  0) int covered
#          1) int total
#
# Returns: reference to GPH::PHPUnit::Stat object
sub add {
    my ($self, $covered, $total) = @_;

    $self->{covered} += $covered;
    $self->{total} += $total;

    return $self;
}

#------------------------------------------------------------------------------
# Calculate percentage for stat
#
# Returns: float
sub percentage {
    my $self = shift;

    return $self->{'total'} != 0 ? (($self->{'covered'} / $self->{'total'}) * 100) : 0;
};

#------------------------------------------------------------------------------
# Calculate percentage for stat
#
# Returns: float
sub coverage {
    my ($self, $name) = @_;

    return(sprintf("  %s:%s%.2f%% (%s/%s)", ucfirst($name), (' ' x (8 - length($name))), $self->percentage(), $self->{covered}, $self->{total}));
};

1;