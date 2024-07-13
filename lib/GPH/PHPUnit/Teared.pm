package GPH::PHPUnit::Teared;

use strict;
use warnings FATAL => 'all';

sub new {
    my ($proto, %args) = @_;

    exists($args{file}) or die "file must be defined: $!";

    my $self = bless {
        file       => $args{file},
        teardown   => $args{teardown} // 0,
        properties => $args{properties} // {},
        teared     => $args{teared} // {},
    }, $proto;

    return ($self);
}

sub isValid {
    my ($self) = @_;
    my $properties = keys %{$self->{properties}};

    if ($properties > 0 && $self->{teardown} == 0) {
        print "file $self->{file} is invalid: has properties, but no teardown\n";

        return(0);
    }

    my @missing = ();
    foreach (keys %{$self->{properties}}) {
        push (@missing, $_) unless exists($self->{teared}{$_});
    }

    @missing = sort @missing;

    my $missing = @missing;

    if ($missing > 0) {
        print "file $self->{file} is invalid: propert" . ($missing == 1 ? "y '": "ies '") . join("', '", @missing) . "' " . ($missing == 1 ? "is ": "are ") .  "not teared down\n";

        return(0);
    }

    return(1);
};

1;

__END__

=head1 NAME

GPH::PHPUnit::Teared - data object for GPH::PHPUnit::Teardown module

=head1 SYNOPSIS

    use GPH::PHPUnit::Teared;

    my $teared = GPH::PHPUnit::Teared->new((file => 'foo.php', teardown => 1, properties => ('bar' => 1), teared => ('bar' => 1)));
    $teared->isValid();

=head1 METHODS

=over 4

=item C<< -E<gt>new(%args) >>

the C<new> method returns a GPH::PHPUnit::Teared object. it takes a hash of options, valid option keys include:

=over

=item file B<(required)>

file (path) name used for validation output.

=item teardown

boolean whether or not the file contains a teardown method (can be tearDown or tearDownAfterClass).

=item properties

hash of class properties of the file

=item teared

hash of class properties which are 'touched' within a teardown method.

=back

=item C<< -E<gt>isValid() >>

validates the teardown behaviour of the file:

 - if it has properties, a teardown method is required.
 - if it has properties and one or more teardown methods, all properties need to be 'touched' within those methods.

returns 1 if valid, 0 otherwise.

=back

=head1 AUTHOR

the GPH::PHPUnit::Teared module was written by wicliff wolda <wicliff.wolda@gmail.com>

=head1 COPYRIGHT AND LICENSE

this library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
