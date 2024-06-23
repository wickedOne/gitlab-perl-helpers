package GPH::Dependency::Fixture;

use strict;
use warnings FATAL => 'all';

sub new {
    my ($proto, %vars) = @_;

    exists($vars{file}) or die "$!";

    my $self = bless {
        file         => $vars{file},
        dependencies => $vars{dependencies} // {},
        inheritance  => $vars{inheritance} // {},
        files        => $vars{files} // {},
        includes     => $vars{includes} // {},
    }, $proto;

    return($self);
}

sub inheritance {
    my ($self, $inheritance) = @_;
    my %merged = (%{$self->{inheritance}}, %{$inheritance});

    $self->{inheritance} = \%merged;

    return($self);
};

1;

__END__

=head1 NAME

GPH::Dependency::Fixture - file data structure (alice data) fixture properties

=head1 SYNOPSIS

    use GPH::Dependency::Fixture;

    my $file = GPH::Dependency::Fixture->new((file => 'tests/fixture.yaml'));

=head1 METHODS

=over 4

=item C<< -E<gt>new(%args) >>

the C<new> method creates a new GPH::Dependency::Fixture. it takes a hash of options, valid option keys include:

=over

=item file B<(required)>

path to the fixture file.

=item dependencies

hash of fully qualified class names of dependencies defined in the fixture file.

=item inheritance

hash of fully qualified class names of dependencies by inheritance.

=item files

hash of fully qualified class names of php files using the fixture file

=item includes

hash of path names to other fixture files imported by the fixture file.

=back

=item C<< -E<gt>inheritance(%inheritance) >>

merge inheritance hash into the GPH::Dependency::Fixture inheritance property.

=back

=head1 AUTHOR

the GPH::Dependency::Fixture module was written by wicliff wolda <wicliff.wolda@gmail.com>

=head1 COPYRIGHT AND LICENSE

this library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut