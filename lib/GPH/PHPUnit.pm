package GPH::PHPUnit;

use strict;
use warnings FATAL => 'all';

use File::Basename;
use lib dirname(__FILE__);

use GPH::Composer;
use GPH::Gitlab;
use GPH::PHPUnit::Stats;

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

    $self->parseBaseline(%args);

    return $self;
}

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

sub parseBaseline {
    my ($self, %args) = @_;
    my ($fh, @lines);

    if (exists($args{baseline}) and defined $args{baseline}) {

        open($fh, '<', $args{baseline}) or die $!;

        @lines = ();

        while (<$fh>) {
            chomp $_;
            push(@lines, $_);
        }
        close($fh);

        $self->{baseline} = \@lines;
    }
}

sub classReport {
    my $self = shift;

    my $report = '';

    foreach my $stats (sort keys %{$self->{classreport}}) {
        $report .= sprintf("%s\n%s\n", $stats, $self->{classreport}{$stats});
    }

    return ($report);
}

1;

__END__

=head1 NAME

GPH::PHPUnit - parses L<PHPUnit|https://phpunit.de/> coverage output and filters it for given code owner.
provides option to fail if coverage is below required threshold

=head1 SYNOPSIS

    use GPH::PHPUnit;

    my $phpunit = GPH::PHPUnit->new((
        owner       => '@teams/alpha',
        codeowners  => './CODEOWNERS,
        classmap    => './vendor/composer/autoload_classmap.php'
    ));

    $phpunit->parse();

=head1 METHODS

=over 4

=item C<< -E<gt>new(%args) >>

the C<new> method creates a new GPH::PHPUnit instance. it takes a hash of options, valid option keys include:

=over

=item owner B<(required)>

code owner name

=item codeowners B<(required)>

path to CODEOWNERS file

=item classmap B<(required)>

path to (optimised) autoload file

=item threshold

minimal line coverage required while parsing. defaults to C<0.0>

=item baseline

path to baseline file which contains paths to ignore while parsing PHPUnit's output

=back

=item C<< -E<gt>parse() >>

parse PHPUnit output from <>, print warning or note when appropriate and return exit code

=item C<< -E<gt>classReport() >>

print matched coverage lines

=item C<< -E<gt>parseBaseline(%args) >> B<< (internal) >>

parse baseline file. takes a hash of options, valid option keys include:

=over

=item baseline

path to baseline file which contains paths to ignore while parsing PHPUnit's output

=back

code owner name

=back

=head1 AUTHOR

the GPH::PHPUnit module was written by wicliff wolda <wicliff.wolda@gmail.com>

=head1 COPYRIGHT AND LICENSE

this library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
