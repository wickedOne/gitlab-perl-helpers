package GPH::PHPUnit::Stat;

use strict;
use warnings FATAL => 'all';

sub new {
    my ($proto) = @_;

    return bless {
        'covered' => 0,
        'total'   => 0,
    }, $proto;
};

sub add {
    my ($self, $covered, $total) = @_;

    $self->{covered} += $covered;
    $self->{total} += $total;

    return $self;
}

sub percentage {
    my $self = shift;

    return $self->{'total'} != 0 ? (($self->{'covered'} / $self->{'total'}) * 100) : 0;
};

sub coverage {
    my ($self, $name) = @_;

    return(sprintf("  %s:%s%.2f%% (%s/%s)", ucfirst($name), (' ' x (8 - length($name))), $self->percentage(), $self->{covered}, $self->{total}));
};

1;

__END__

=head1 NAME

GPH::PHPUnit::Stat - statistic collection for GPH::PHPUnit::Stats module

=head1 SYNOPSIS

    use GPH::PHPUnit::Stat;

    my $stat = GPH::PHPUnit::Stat->new();

    $stats->add(10, 13);
    my $percentage = $stats->percentage();

=head1 METHODS

=over 4

=item C<< -E<gt>new() >>

the C<new> method returns a stat object.

=item C<< -E<gt>add($covered, $total) >>

increments covered and total properties of the C<Stat> object with given values.

=item C<< -E<gt>percentage() >>

calculates the coverage percentage based on current property values

=item C<< -E<gt>coverage($name) >>

returns coverage 'summary' line for current stat.

=back

=head1 AUTHOR

the GPH::PHPUnit::Stat module was written by wicliff wolda <wicliff.wolda@gmail.com>

=head1 COPYRIGHT AND LICENSE

this library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
