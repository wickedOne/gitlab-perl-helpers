#------------------------------------------------------------------------------
# File:         Stats.pm
#
# Description:  Processes PHPUnit coverage output statistics
#
# Revisions:    2024-02-10 - created
#------------------------------------------------------------------------------
package GPH::PHPUnit::Stats;

use strict;
use warnings FATAL => 'all';

use Time::Piece;
use GPH::PHPUnit::Stat;

use File::Basename;
use lib dirname(__FILE__);

#------------------------------------------------------------------------------
# Construct new GPH::PHPUnit::Stats class
#
# Inputs:  0) string code owner
#          1) float minimal coverage percentage threshold
#
# Returns: reference to GPH::PHPUnit::Stats object
sub new {
    my ($proto, $owner, $threshold) = @_;

    my $self = {
        'owner' => $owner,
        'threshold' => sprintf("%.2f", $threshold),
        'classes' => GPH::PHPUnit::Stat->new(),
        'methods' => GPH::PHPUnit::Stat->new(),
        'lines' => GPH::PHPUnit::Stat->new(),
    };

    bless $self, $proto;

    return $self;
};

#------------------------------------------------------------------------------
# Convert PHPUnit coverage output and track separately
#
# Inputs:  0) string statistics from PHPUnit's coverage output
#
# Returns: reference to GPH::PHPUnit::Stats object
sub add {
    my ($self, $stats) = @_;
    my ($methodsCovered, $methodsTotal, $linesCovered, $linesTotal) = $stats =~ /[\s]?Methods:[^\(]+\([\s]{0,}([\d]+)\/[\s]{0,}([\d]+)\)[\s]+Lines[^\(]+\([\s]{0,}([\d]+)\/[\s]{0,}([\d]+)\)/;

    $self->{classes}->add(($methodsCovered == $methodsTotal ? 1 : 0), 1) unless $methodsTotal == 0;
    $self->{methods}->add($methodsCovered, $methodsTotal);
    $self->{lines}->add($linesCovered, $linesTotal);

    return $self;
};

#------------------------------------------------------------------------------
# Define exit code based on line coverage percentage and defined threshold
#
# Returns: int | exit code
sub exitCode {
    my $self = shift;

    return($self->{lines}->percentage() >= $self->{threshold} ? 0 : 1);
};

#------------------------------------------------------------------------------
# Generate summary from collected statistics
#
# Returns: string
sub summary {
    my $self = shift;
    my $dt = localtime->datetime =~ y/T/ /r;

    return(sprintf(
        "Code Coverage Report for %s:\n  %s\n\nSummary:\n%s\n%s\n%s\n\n",
        $self->{owner},
        $dt,
        $self->{classes}->coverage('classes'),
        $self->{methods}->coverage('methods'),
        $self->{lines}->coverage('lines'),
    ));
};

#------------------------------------------------------------------------------
# Generate footer based on coverage percentage and defined threshold
#
# Returns: string
sub footer {
    my $self = shift;

    if ($self->{lines}->percentage() > $self->{threshold}) {
        return(sprintf(
            "\n ! [NOTE] Your coverage is %.2f%% percentage points over the required coverage.\n !%sConsider increasing the required coverage percentage.\n",
            ($self->{lines}->percentage() - $self->{threshold}),
            ' ' x 8
        ))
    }

    if ($self->{lines}->percentage() < $self->{threshold}) {
        return(sprintf(
            "\n ! [FAILED] Your coverage is %.2f%% percentage points under the required coverage.\n !%sPlease increase coverage by improving your tests.\n",
            ($self->{threshold} - $self->{lines}->percentage()),
            ' ' x 10
        ))
    }
};

1;