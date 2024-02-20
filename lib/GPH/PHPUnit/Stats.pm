package GPH::PHPUnit::Stats;

use strict;
use warnings FATAL => 'all';

use Time::Piece;
use GPH::PHPUnit::Stat;

use File::Basename;
use lib dirname(__FILE__);

sub new {
    my ($proto, %args) = @_;

    exists($args{owner}) or die "$!";

    my $threshold = $args{threshold} || 0.0;

    my $self = {
        'owner' => $args{owner},
        'threshold' => sprintf("%.2f", $threshold),
        'classes' => GPH::PHPUnit::Stat->new(),
        'methods' => GPH::PHPUnit::Stat->new(),
        'lines' => GPH::PHPUnit::Stat->new(),
    };

    bless $self, $proto;

    return $self;
};

sub add {
    my ($self, $stats) = @_;
    my ($methodsCovered, $methodsTotal, $linesCovered, $linesTotal) = $stats =~ /[\s]?Methods:[^\(]+\([\s]{0,}([\d]+)\/[\s]{0,}([\d]+)\)[\s]+Lines[^\(]+\([\s]{0,}([\d]+)\/[\s]{0,}([\d]+)\)/;

    $self->{classes}->add(($methodsCovered == $methodsTotal ? 1 : 0), 1) unless $methodsTotal == 0;
    $self->{methods}->add($methodsCovered, $methodsTotal);
    $self->{lines}->add($linesCovered, $linesTotal);

    return $self;
};

sub exitCode {
    my $self = shift;

    return($self->{lines}->percentage() >= $self->{threshold} ? 0 : 1);
};

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

sub footer {
    my $self = shift;
    my $percentage = sprintf("%.2f", $self->{lines}->percentage());

    if ($percentage > $self->{threshold}) {
        return(sprintf(
            "\n ! [NOTE] Your coverage is %.2f%% percentage points over the required coverage.\n !%sConsider increasing the required coverage percentage.\n",
            ($self->{lines}->percentage() - $self->{threshold}),
            ' ' x 8
        ));
    }

    if ($percentage < $self->{threshold}) {
        return(sprintf(
            "\n ! [FAILED] Your coverage is %.2f%% percentage points under the required coverage.\n !%sPlease increase coverage by improving your tests.\n",
            ($self->{threshold} - $self->{lines}->percentage()),
            ' ' x 10
        ));
    }
};

1;

__END__

=head1 NAME

GPH::PHPUnit::Stats - statistics processing for GPH::PHPUnit module

=head1 SYNOPSIS

    use GPH::PHPUnit::Stats;

    my $stats = GPH::PHPUnit::Stats->new((owner => '@teams/alpha', threshold => 97.96));

    $stats->add('Methods:  50.00% ( 1/ 2)   Lines:  76.92% ( 10/ 13)');
    my $summary = $stats->summary();

=head1 METHODS

=over 4

=item C<< -E<gt>new(%args) >>

the C<new> method returns a stats object.

the parameter list of the constructor is a hash which I<must> contain an 'owner' and I<might> contain a 'threshold' (defaults to 0.0)

    GPH::PHPUnit::Stats->new((
        owner => '@teams/alpha',
        threshold => 97.96,
    ));

=item C<< -E<gt>add($stats) >>

parses given statistics line and adds the values to the stat collections (classes, methods, lines).
note that the statistics line is expected to be formatted as phpunit's coverage-text output.

C<-E<gt>add('Methods:  50.00% ( 1/ 2)   Lines:  76.92% ( 10/ 13)');>

=item C<< -E<gt>exitCode() >>

returns exit code based on line coverage and given threshold;
if line coverage is greater than or equal to the threshold exit code C<0> will be returned, C<1> otherwise.

=item C<< -E<gt>summary() >>

returns phpunit coverage summary based on current stat collections.

=item C<< -E<gt>footer() >>

returns footer based on lie coverage; in case line coverage is greater than the threshold, a note suggesting the
threshold should be increased is returned. in case line coverage is lower than the threshold, a note stating that
the coverage is too low is returned. in case the line coverage equals the threshold nothing is returned.

=back

=head1 AUTHOR

the GPH::PHPUnit::Stats module was written by wicliff wolda <wicliff.wolda@gmail.com>

=head1 COPYRIGHT AND LICENSE

this library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
