#------------------------------------------------------------------------------
# File:         PHPUnit.pm
#
# Description:  Parses PHPUnit coverage output and filters it for given 
#               code owner. Provides option to fail if coverage is below
#               rquired threshold
#
# Revisions:    2023-01-21 - created
#------------------------------------------------------------------------------
package PHPUnit;

use strict;
use warnings;

use Time::Piece;

use File::Basename;
use lib dirname(__FILE__);

use Composer;
use Gitlab;

#------------------------------------------------------------------------------
# Static properties
# accumulated owner specific coverage statistics for classes, lines and methods
my %classes = (
    'total'   => 0,
    'covered' => 0,
);

my %lines = (
    'total'   => 0,
    'covered' => 0,
);

my %methods = (
    'total'   => 0,
    'covered' => 0,
);

my %classreport = ();

#------------------------------------------------------------------------------
# Construct new PHPUnit class
#
# Inputs:  0) string code owner
#          1) string path to code owners file
#          2) string path to classmap file
#          3) float minimal coverage percentage treshold, defaults to 0.0
#
# Returns: reference to PHPUnit object
sub new {
    my ($class, $owner, $codeowners, $classmap, $threshold) = @_;

    my $gitlab = Gitlab->new($codeowners, $owner);
    my $composer = Composer->new($classmap);

    my $self = {
        gitlab    => $gitlab,
        composer  => $composer,
        owner     => $owner,
        threshold => $threshold || 0.0,
    };

    bless $self, $class;

    return $self;
}

#------------------------------------------------------------------------------
# Parses PHPUnit coverage-text output
#
# Returns: int | exit code
sub Parse {
    my ($self) = @_;

    while (<>) {
        chomp $_;

        # ignore lines with spaces
        next unless $_ =~ /[^ ]/;
        next unless $self->{composer}->Match($_, $self->{gitlab}->GetPaths());

        # read next line for stats
        my $stats = <>;

        $self->CollectStats($_, $stats);
    }

    $self->Report();

    return ($self->Summary());
}

#------------------------------------------------------------------------------
# Print PHPUnit owner specific summary
#
# Returns: int
sub Summary {
    my ($self) = @_;

    my $score = (($lines{'covered'} / $lines{'total'}) * 100);

    if ($self->{threshold} > $score) {
        print "\n ! [FAILED] Your coverage is ";
        printf("%.2f", ($self->{threshold} - $score));
        print "% percentage points under the required coverage.\n !          Please increase coverage by improving your tests.\n";

        return (1);
    }

    if ($self->{threshold} < $score) {
        print "\n ! [NOTE] Your coverage is ";
        printf("%.2f", ($score - $self->{threshold}));
        print "% percentage points over the required coverage.\n !        Consider increasing the required coverage percentage.\n"
    }

    return (0);
}

#------------------------------------------------------------------------------
# Print PHPUnit owner specific report
#
# Returns: void
sub Report {
    my ($self) = @_;

    my $dt = localtime->datetime =~ y/T/ /r;

    print "Code Coverage Report for $self->{owner}:\n  $dt\n\n";
    print " Summary:\n";

    if ($classes{'total'} != 0) {
        print "  Classes: ";
        printf("%.2f", (($classes{'covered'} / $classes{'total'}) * 100));
        print "% (" . $classes{'covered'} . "/" . $classes{'total'} . ")\n";
    }

    if ($methods{'total'} != 0) {
        print "  Methods: ";
        printf("%.2f", (($methods{'covered'} / $methods{'total'}) * 100));
        print "% (" . $methods{'covered'} . "/" . $methods{'total'} . ")\n";
    }

    if ($lines{'total'} != 0) {
        print "  Lines:   ";
        printf("%.2f", (($lines{'covered'} / $lines{'total'}) * 100));
        print "% (" . $lines{'covered'} . "/" . $lines{'total'} . ")\n\n";
    }

    while (my ($key, $value) = each %classreport) {
        print "$key\n$value\n";
    }
}

#------------------------------------------------------------------------------
# Collect PHPUnit owner specific statistics
#
# Returns: int
sub CollectStats {
    my ($self, $class, $stats) = @_;

    chomp $stats;

    # collect for output
    $classreport{$class} = $stats;

    my ($methodsCovered, $methodsTotal, $linesCovered, $linesTotal) = $stats =~ /[\s]?Methods:[^\(]+\([\s]{0,}([\d]+)\/[\s]{0,}([\d]+)\)[\s]+Lines[^\(]+\([\s]{0,}([\d]+)\/[\s]{0,}([\d]+)\)/;

    if ($methodsTotal != 0) {
        $classes{'total'}++;

        if ($methodsTotal == $methodsCovered) {
            $classes{'covered'}++;
        }
    }

    $methods{'covered'} += $methodsCovered;
    $methods{'total'} += $methodsTotal;

    $lines{'covered'} += $linesCovered;
    $lines{'total'} += $linesTotal;
}

1;