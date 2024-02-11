#------------------------------------------------------------------------------
# File:         GPH::PHPUnit.pm
#
# Description:  Parses GPH::PHPUnit coverage output and filters it for given
#               code owner. Provides option to fail if coverage is below
#               required threshold
#
# Revisions:    2023-01-21 - created
#               2024-01-23 - added baseline option to ignore certain paths / files
#                            within owner's code-space.
#                            sort stats output for ease of lookup
#               2024-02-10 - namespaced module, bugfixes and unit tests
#               2024-02-11 - constructor now requires named arguments
#------------------------------------------------------------------------------
package GPH::PHPUnit;

use strict;
use warnings FATAL => 'all';

use File::Basename;
use lib dirname(__FILE__);

use GPH::Composer;
use GPH::Gitlab;
use GPH::PHPUnit::Stats;

#------------------------------------------------------------------------------
# Construct new GPH::PHPUnit class
#
# Inputs:  owner      => (string) code owner
#          codeowners => (string) path to code owners file
#          classmap   => (string) path to classmap file
#          threshold  => (float) minimal coverage percentage threshold, defaults to 0.0
#          excludes   => (array) code owner paths to exclude
#          baseline   => (string) path to baseline file, defaults to undef
#
# Returns: reference to GPH::PHPUnit object
sub new {
    my ($class, %args) = @_;

    (exists($args{owner}) and exists($args{codeowners}) and exists($args{classmap})) or die "$!";

    my $self = {
        owner       => $args{owner},
        threshold   => $args{threshold} || 0.0,
        stats       => GPH::PHPUnit::Stats->new(%args),
        classreport => {},
        baseline    => [],
        gitlab      => GPH::Gitlab->new(%args),
        composer    => GPH::Composer->new(%args),
    };

    bless $self, $class;

    if (exists($args{baseline})) {
        open(my $fh, '<', $args{baseline}) or die "unable to open phpunit baseline file $args{baseline} $!";
        my @lines = ();

        while (<$fh>) {
            chomp $_;
            push(@lines, $_);
        }
        close($fh);

        $self->{baseline} = \@lines;
    }

    return $self;
}

#------------------------------------------------------------------------------
# Parses PHPUnit coverage-text output from stdin
#
# Returns: int | exit code
sub parse {
    my ($self) = @_;

    while (<>) {
        chomp $_;

        # ignore lines with spaces
        next unless $_ =~ /^[^ ]+$/;

        next unless $self->{composer}->match($_, @{$self->{gitlab}->getPaths()});
        next if $self->{composer}->match($_, @{$self->{baseline}});
        next if $self->{composer}->match($_, @{$self->{gitlab}->getBlacklistPaths()});
        # read next line for stats
        my $stats = <>;

        $self->{classreport}{$_} = $stats;
        $self->{stats}->add($stats);
    }

    # print report
    print $self->{stats}->summary() . $self->classReport() . $self->{stats}->footer();

    return ($self->{stats}->exitCode());
}

#------------------------------------------------------------------------------
# Print PHPUnit Class report
#
# Returns: string
sub classReport {
    my $self = shift;

    my $report = '';

    foreach my $stats (sort keys %{$self->{classreport}}) {
        $report .= sprintf("%s\n%s\n", $stats, $self->{classreport}{$stats});
    }

    return ($report);
}

1;
