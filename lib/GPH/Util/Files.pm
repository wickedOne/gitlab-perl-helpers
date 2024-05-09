package GPH::Util::Files;

use strict;
use warnings FATAL => 'all';

sub new {
    my ($proto) = @_;
    my $self = bless {}, $proto;
    return $self;
};

sub segment {
    my ($self, %args) = @_;
    my (@arr, $group, %result, $depth, $path, $key, $size);

    (exists($args{paths})) or die "$!";
    $depth = $args{depth} || 1;


    foreach $path (@{$args{paths}}) {
        @arr = split(/\//, $path, $depth + 1);
        $group = join('.', @arr[0..$depth - 1]);

        $result{$group} = [] unless defined($result{$group});
        push(@{$result{$group}}, $path);
    }

    return(%result) unless defined $args{max};

    foreach $key (keys %result) {
        $size = scalar(@{$result{$key}});
        next unless $size > $args{max};

        my $index = 1;

        while (scalar(@{$result{$key}}) > $args{max}) {
            my @segment = splice @{$result{$key}}, 0, $args{max};
            $result{$key . '.' . $index} = \@segment;
            $index++;
        }
    }

    return(%result);
};

1;

__END__

=head1 NAME

GPH::Util::Files - file related util methods

=head1 SYNOPSIS

    use GPH::Util::Files;

    my $util = GPH::Util::Files->new();

    $util->segment(wq(Foo/Bar/baz.php Foo/Qux/Fred.php));

=head1 METHODS

=over 4

=item C<< -E<gt>new() >>

the C<new> method returns a new GPH::Util::Files object.

=item C<< -E<gt>segment(%args) >>

return an hash of segments based on given file path collection. the segment method takes a hash of options, valid option keys include:

=over

=item paths B<(required)>

file paths to segment.

=item depth

the path depth from which to create the segments. defaults to 1.

=item max

the maximum number of files per segment.

=back

=back

=head1 AUTHOR

the GPH::Util::Files module was written by wicliff wolda <wicliff.wolda@gmail.com>

=head1 COPYRIGHT AND LICENSE

this library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut