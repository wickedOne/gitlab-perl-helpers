package GPH::Dependency::DependencyMapBuilder;

use strict;
use warnings FATAL => 'all';

sub new {
    my ($proto, %args) = @_;

    my $self = bless {
        plugins      => [],
        files        => $args{files} // {},
        dependencies => {},
        traits       => {},
        inheritance  => {},
        map          => {},
        packages     => $args{packages} // ['PHPUnit', 'Symfony', 'Monolog', 'PHPStan'],
    }, $proto;

    return ($self);
}

sub plugins {
    my ($self, $plugins) = @_;

    foreach my $plugin (@{$plugins}) {
        bless $plugin, ref $plugin;

        die "'files' method not defined for " . ref $plugin unless $plugin->can('files');

        push(@{$self->{plugins}}, $plugin);
    }

    return ($self);
};

sub build {
    my ($self) = @_;
    my ($file, $dependency);

    $self
        ->collect()
        ->prepare()
        ->traits()
        ->inheritance()
    ;

    foreach $file (values %{$self->{inheritance}}) {
        next if $file->{valid} == 0;

        foreach $dependency (keys %{$file->{inheritance}}) {
            $self->{map}{$dependency}{$file->{file}} = 1;
        }
    }

    return($self);
};

sub filter {
    my ($self, %args) = @_;
    my (%files);

    (exists($args{collection})) or die "$!";

    foreach my $namespace (@{$args{collection}}) {
        %files = (%files, %{$self->{map}{$namespace}}) unless !defined $self->{map}{$namespace};
    }

    return (sort keys %files);
}

sub collect {
    my ($self) = @_;

    foreach my $plugin (@{$self->{plugins}}) {
        bless $plugin, ref $plugin;

        foreach my $file (values %{$plugin->files()}) {
            if (defined($self->{files}{$file->{file}})) {
                $self->{files}{$file->{file}}->merge($file);
            }
            else {
                $self->{files}{$file->{file}} = $file;
            }
        }
    }

    return ($self);
};

sub prepare {
    my ($self) = @_;
    my ($file, $dependency);

    foreach $file (values %{$self->{files}}) {
        if ($file->{type} eq 'trait') {
            $self->{traits}{$file->{fqcn}} = $file->{file};
        }

        foreach $dependency (keys %{$file->{dependencies}}) {
            $self->{dependencies}{$dependency} = {} unless defined($self->{dependencies}{$dependency});
            $self->{dependencies}{$dependency}{$file->{file}} = 1;
        }
    }

    return ($self);
};

sub traits {
    my ($self) = @_;
    my ($trait, $key, $path);

    foreach $key (keys %{$self->{traits}}) {
        $trait = $self->{files}{$self->{traits}{$key}};

        foreach $path (keys %{$self->{dependencies}{$key}}) {
            $self->{files}{$path}->dependencies($trait);
        }
    }

    return ($self)
};

sub inheritance {
    my ($self) = @_;
    my ($fqcn, $file, $parent, $extends);

    # copy files to new map
    foreach $file (values %{$self->{files}}) {
        $self->{inheritance}{$file->{fqcn}} = $file;
    }

    foreach $file (values %{$self->{inheritance}}) {
        # copy original dependencies to the inheritance map
        $self->{inheritance}{$file->{fqcn}}->inheritance($file);
        $fqcn = $file->{extends};

        while (defined $fqcn and defined ($parent = $self->{inheritance}{$fqcn})) {
            $self->{inheritance}{$file->{fqcn}}->inheritance($parent);

            $fqcn = $self->{inheritance}{$fqcn}{extends};
        }

        $extends = defined $fqcn ? $fqcn : $file->{extends};

        $self->{inheritance}{$file->{fqcn}}{valid} = $self->package($extends);
    }

    return ($self);
};

sub package {
    my ($self, $fqcn) = @_;

    return 0 unless defined $fqcn;

    foreach my $package (@{$self->{packages}}) {
        return 1 if $fqcn =~ $package;
    }

    return 0;
};

1;

__END__

=head1 NAME

GPH::Dependency::DependencyMapBuilder - a php dependency map builder

=head1 SYNOPSIS

    use GPH::Dependency::DependencyMapBuilder;

    my $builder = GPH::Dependency::DependencyMapBuilder->new()
        ->plugins([$fixtures, $php])
        ->build()
    ;

    $builder->filter((collection => \@namespaces))

=head1 METHODS

=over 4

=item C<< -E<gt>new(%args) >>

the C<new> method creates a new GPH::Dependency::DependencyMapBuilder. . it takes a hash of options, valid option keys include:

=over

=item files

a collection of GPH::Dependency::File objects.

=item packages

a collection of package names / test cases which provide a valid phpunit test case extension.

=back

=item C<< -E<gt>plugins(@plugins) >>

register an array of GPH::Dependency::DependencyMapBuilder plugins. each plugin should implement a C<< -E<gt>files() >>
method which should return a collection of GPH::Dependency::File objects.

=item C<< -E<gt>build() >>

collect GPH::Dependency::File objects, resolve their dependencies and build a dependency map.

=item C<< -E<gt>filter(%args) >>

filter the dependency map based on the input of an array of fully qualified class names. it takes a hash of options, valid option keys include:

=over

=item collection B<(required)>

an array of fully qualified class names used to filter the dependency map.

=back

=item C<< -E<gt>collect() >> B<(internal)>

use registered plugins to collect and merge GPH::Dependency::File objects.

=item C<< -E<gt>prepare() >> B<(internal)>

build temporary dependency map which is needed internally to be able to resolve trait dependencies.

=item C<< -E<gt>traits() >> B<(internal)>

process trait dependencies by merging them into the files using them.

=item C<< -E<gt>inheritance() >> B<(internal)>

process class inheritance.

=item C<< -E<gt>package($fqcn) >> B<(internal)>

check whether the $fqcn value matches one of the values defined in the C<< $self->{packages} >> property.

=back

=head1 AUTHOR

the GPH::Dependency::DependencyMapBuilder module was written by wicliff wolda <wicliff.wolda@gmail.com>

=head1 COPYRIGHT AND LICENSE

this library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut