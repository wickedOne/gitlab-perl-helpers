package GPH::Dependency::File;

use strict;
use warnings FATAL => 'all';

sub new {
    my ($proto, %args) = @_;

    exists($args{file}) or die "file must be defined: $!";

    my $self = bless {
        file         => $args{file},
        fqcn         => $args{fqcn} // undef,
        dependencies => $args{dependencies} // {},
        extends      => $args{extends} // undef,
        type         => $args{type} // undef,
        fixtures     => $args{fixtures} // {},
        inheritance  => $args{inheritance} // {},
        valid        => $args{valid} // 0,
    }, $proto;

    return($self);
}

sub merge {
    my ($self, $file) = @_;
    my (%dependencies, %fixtures, %inheritance);

    ref($file) eq 'GPH::Dependency::File' && $self->{file} eq $file->{file} or die "$!";

    $self->{fqcn} = $self->{fqcn} // $file->{fqcn};
    $self->{extends} = $self->{extends} // $file->{extends};
    $self->{type} = $self->{type} // $file->{type};

    %dependencies = (%{$self->{dependencies}}, %{$file->{dependencies}});
    $self->{dependencies} = \%dependencies;

    %fixtures = (%{$self->{fixtures}}, %{$file->{fixtures}});
    $self->{fixtures} = \%fixtures;

    %inheritance = (%{$self->{inheritance}}, %{$file->{inheritance}});
    $self->{inheritance} = \%inheritance;

    return($self);
};

sub dependencies {
    my ($self, $file) = @_;

    die "can't inherit dependencies from " . ref $file unless ref $file eq 'GPH::Dependency::File';

    my %dependencies = (%{$self->{dependencies}}, %{$file->{dependencies}});
    $self->{dependencies} = \%dependencies;
};

sub inheritance {
    my ($self, $file) = @_;

    die "can't inherit from " . ref $file unless ref $file eq 'GPH::Dependency::File';

    my %inheritance = (%{$self->{inheritance}}, %{$file->{dependencies}});

    $self->{inheritance} = \%inheritance;

    return($self);
};

1;

__END__

=head1 NAME

GPH::Dependency::File - file data structure containing php class properties

=head1 SYNOPSIS

    use GPH::Dependency::File;

    my $file = GPH::Dependency::File->new((file => 'src/Foo.php'));

=head1 METHODS

=over 4

=item C<< -E<gt>new(%args) >>

the C<new> method creates a new GPH::Dependency::File. it takes a hash of options, valid option keys include:

=over

=item file B<(required)>

path to the php file.

=item fqcn

fully qualified class name of the php file

=item dependencies

hash of fully qualified class names of dependencies (e.g. use statements) of the php file.

=item extends

fully qualified class name of the class which the php file extends.

=item type

class type (e.g. C<class>, C<enum>, C<trait>) of the php file.

=item fixtures

hash of paths to fixture files used by the php file.

=item inheritance

hash of fully qualified class names of dependencies by inheritance.

=item valid

validity boolean, can be used for filtering a collection of GPH::Dependency::File objects.

=back

=item C<< -E<gt>merge($file) >>

merge property values of another GPH::Dependency::File C<$file> instance. the dependencies, inheritance and fixtures hashes will be merged
while for the remaining properties (except for valid) the value of the current GPH::Dependency::File instance take precedence over those
of the GPH::Dependency::File instance being merged.

the file property of both instances need to match, otherwise the merge will die.

=item C<< -E<gt>inheritance($file) >>

merge dependencies values of another GPH::Dependency::File C<$file> instance into the inheritance property.

=back

=head1 AUTHOR

the GPH::Dependency::File module was written by wicliff wolda <wicliff.wolda@gmail.com>

=head1 COPYRIGHT AND LICENSE

this library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut