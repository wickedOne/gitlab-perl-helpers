package GPH::Infection;

use strict;
use warnings FATAL => 'all';

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

__END__

=head1 NAME

GPH::Infection - parse output generated by L<infection|https://infection.github.io/> and return alternate exit code
when both msi and covered msi meet the configured threshold, but there are escaped mutants.

=head1 SYNOPSIS

    use GPH::Infection;

    my $infection = GPH::Infection->new((
        msi     => 95.2,
        covered => 100.00,
    ));

    exit($infection->parse());

=head1 METHODS

=over 4

=item C<< -E<gt>new(%args) >>

the C<new> method creates a new GPH::Infection instance. it takes a hash of options, valid option keys include:

=over

=item msi B<(required)>

minimum mutation score indicator

=item covered B<(required)>

minimum covered msi

=item exit_code

exit code to return when the thresholds are met, but there are escaped mutants. defaults to C<8>

=back

=item C<< -E<gt>parse() >>

parse infection output from <>, print warning when appropriate and return exit code

=back

=head1 AUTHOR

the GPH::Infection module was written by wicliff wolda <wicliff.wolda@gmail.com>

=head1 COPYRIGHT AND LICENSE

this library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut