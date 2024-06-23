package GPH::Dependency::AliceFixturesPlugin;

use strict;
use warnings FATAL => 'all';

use File::Basename;
use lib dirname(__FILE__);

use File::Find::Rule;
use GPH::Dependency::Fixture;
use GPH::Dependency::File;

sub new {
    my ($proto, %args) = @_;
    (exists($args{fixture_directories}) && exists($args{strip}) && exists($args{directories})) or die "$!";

    my $self = bless {
        fixture_directories => $args{fixture_directories},
        fixture_excludes    => $args{fixture_excludes} // undef,
        directories         => $args{directories},
        excludes            => $args{excludes} // undef,
        strip               => $args{strip},
        type                => $args{type} // 1,
        fixtures            => $args{fixtures} // {},
        classes             => $args{classes} // {},
        usages              => {},
        inheritance         => {},
    }, $proto;

    return ($self);
}

sub files {
    my ($self) = @_;

    $self
        ->yaml()
        ->php()
        ->inheritance()
        ->resolve()
        ->dependencies()
    ;

    return ($self->{'inheritance'});
};

sub yaml {
    my ($self) = @_;

    my $rule = File::Find::Rule->new;

    if (defined $self->{fixture_excludes}) {
        $rule->or(
            $rule->new->exec(sub {
                my ($shortname, $path, $fullname) = @_;
                foreach my $exclude (@{$self->{fixture_excludes}}) {
                    return 1 if $fullname =~ $exclude;
                }
                return 0;
            })->prune->discard,
            $rule->new
        );
    }

    my @files = $rule->name('*.yml', '*.yaml')->in(@{$self->{fixture_directories}});

    foreach my $path (@files) {
        $self->parseYaml($path)
    }

    return ($self);
};

sub parseYaml {
    my ($self, $path) = @_;
    my ($fh, $in_import);

    return $self unless $path =~ '[/]{0,}([^/]+)\.[yml|yaml]{3,4}$';

    open($fh, '<', $path) or die "unable to open file $path : $!";

    $path =~ s/$self->{strip}//g;

    $self->{fixtures}{$path} = GPH::Dependency::Fixture->new((file => $path));
    $in_import = 0;

    while (<$fh>) {
        chomp $_;
        next unless $_ =~ /^\\?([^\s#]+):$/;
        my $dependency = $1;

        $in_import = $dependency eq 'include' ? 1 : 0;

        while ($in_import == 1) {
            my $import = <$fh>;
            chomp $import;

            if ($import =~ /^\s*-\s*([^\s]+)$/) {
                my $realpath = $self->realpath(dirname($path) . "/" . $1);
                $self->{fixtures}{$path}{includes}{$realpath} = 1;
            }
            else {
                $in_import = 0;
            }
        }

        $self->{fixtures}{$path}{dependencies}{$1} = 1 unless $dependency eq 'include';
    }
};

sub php {
    my ($self) = @_;

    my $rule = File::Find::Rule->new;

    if (defined $self->{excludes}) {
        $rule->or(
            $rule->new->exec(sub {
                my ($shortname, $path, $fullname) = @_;
                foreach my $exclude (@{$self->{excludes}}) {
                    return 1 if $fullname =~ $exclude;
                }
                return 0;
            })->prune->discard,
            $rule->new
        );
    }

    my @files = $rule->name('*.php')->in(@{$self->{directories}});

    foreach my $file (@files) {
        $self->parsePhp($file);
    }

    return ($self);
};

sub parsePhp {
    my ($self, $path) = @_;
    my ($fh, $namespace, $fqcn, $class, $type);

    return $self unless $path =~ '[/]{0,}([^/]+)\.php$';

    open($fh, '<', $path) or die "unable to open file $path : $!";

    $class = $1;

    $path =~ s/$self->{strip}//g;

    while (<$fh>) {
        chomp $_;

        next if $_ =~ /^[\s]{0,}[\/]{0,1}[\*]{1,2}/ or $_ eq '' or $_ =~ /^[\s]*\/\//;

        # get namespace
        if ($_ =~ /^namespace (.*);$/) {
            $namespace = $1;

            next;
        }

        if ($_ =~ "[ ]{0,}([^ ]+) $class(?:[ :]|\$){1,}") {
            $type = $self->{type} == 1 ? $1 : undef;
            $fqcn = $namespace . '\\' . $class;

            next;
        }

        next unless $_ =~ /'([^']+\.[yaml|yml]{3,4})'/;

        $self->{classes}{$path} = GPH::Dependency::File->new((fqcn => $fqcn, file => $path, type => $type)) unless defined $self->{classes}{$path};

        $self->{classes}{$path}{fixtures}{$self->realpath($1)} = 1;
    }
};

sub inheritance {
    my ($self) = @_;

    foreach my $key (keys %{$self->{fixtures}}) {
        $self->{fixtures}{$key}->inheritance($self->processInheritance($key, {}));
    }

    return ($self);
};

sub processInheritance {
    my ($self, $key, $seen) = @_;
    my (%result, $include);

    return \%result unless defined $self->{fixtures}->{$key};

    %result = (%result, %{$self->{fixtures}->{$key}->{dependencies}});

    foreach $include (keys %{$self->{fixtures}->{$key}->{includes}}) {
        next if $seen->{$include};
        $seen->{$include} = 1;
        %result = (%result, %{$self->processInheritance($include, $seen)});
    }

    return (\%result);
};

sub resolve {
    my ($self) = @_;
    my ($class, $fixture, $file);

    foreach $class (keys %{$self->{classes}}) {
        foreach $fixture (keys %{$self->{classes}{$class}{fixtures}}) {
            foreach $file (keys %{$self->{fixtures}}) {
                next unless $file =~ $fixture;

                $self->{fixtures}{$file}{files}{$class} = 1;
            }
        }
    }

    return ($self);
};

sub dependencies {
    my ($self) = @_;
    my ($fixture, $file, $class);

    foreach $fixture (keys %{$self->{fixtures}}) {
        foreach $file (keys %{$self->{fixtures}{$fixture}{files}}) {
            $class = $self->{classes}{$file};
            $self->{'inheritance'}{$file} = $class->merge(GPH::Dependency::File->new((
                file         => $file,
                dependencies => \%{$self->{fixtures}{$fixture}{inheritance}}))
            );
        }
    }

    return ($self);
};

sub realpath {
    my ($self, $path) = @_;
    my @c = reverse split(m@/@, $path);
    my @c_new;

    while (@c) {
        my $component = shift @c;
        next unless length($component);
        if ($component eq ".") {next;}
        if ($component eq "..") {
            shift @c;
            next;
        }
        push(@c_new, $component);
    }

    return join("/", reverse @c_new);
};

1;

__END__

=head1 NAME

GPH::Dependency::AliceFixturesPlugin - a GPH::Dependency::DependencyMapBuilder plugin which extracts (alice data) fixture
dependencies and assigns them to php classes using them.

=head1 SYNOPSIS

    use GPH::Dependency::AliceFixturesPlugin;

    my $fixtures = GPH::Dependency::AliceFixturesPlugin->new((
        type        => 0,
        strip       => '/Users/foo/',
        fixtures    => [ '/Users/foo/tests/fixtures' ],
        directories => [ '/Users/foo/tests/Functional' ],
        excludes    => [ '/Users/foo/tests/Functional/Bar' ]
    ));

    my $files = $fixtures->files();

=head1 METHODS

=over 4

=item C<< -E<gt>new(%args) >>

the C<new> method creates a new GPH::Dependency::AliceFixturesPlugin. it takes a hash of options, valid option keys include:

=over

=item fixtures B<(required)>

array of paths of directories containing fixture files.

=item directories B<(required)>

array of paths of directories containing php files using fixtures.

=item strip B<(required)>

string defining which bit should be stripped of the filepath

=item excludes

array of paths of directories containing php files which to ignore.

=item type

boolean value defining whether or not to resolve the php type (e.g. class, interface) during parsing.

=back

=item C<< -E<gt>files() >>

parse fixture and php files, define and resolve dependencies and return a collection of GPH::Dependency::File objects.

=item C<< -E<gt>yaml() >> B<(internal)>

iterate over yaml files contained in the C<$self->{fixture_directories}> property and parse them through the parseYaml method.

=item C<< -E<gt>parseYaml() >> B<(internal)>

parse fixture files, define and resolve their dependencies.

=item C<< -E<gt>php() >> B<(internal)>

iterate over php files contained in the C<$self->{directories}> property and parse them through the parsePhp method.

=item C<< -E<gt>parsePhp($file) >> B<(internal)>

parse php file located at filepath $file, define and resolve it's fixture dependencies.

=item C<< -E<gt>inheritance() >> B<(internal)>

iterate over fixtures defined in the C<$self->{fixtures}> property.

=item C<< -E<gt>processInheritance($key, %seen) >> B<(internal)>

process inheritance for the GPH::Dependency::Fixture file defined in the C<$self->{fixtures}{$key}> property.
the C<%seen> argument usually is an empty hash which is used internally to bypass circular references.

=item C<< -E<gt>resolve() >> B<(internal)>

assign php classes to GPH::Dependency::Fixture objects

=item C<< -E<gt>dependencies() >> B<(internal)>

assign fixture dependencies to GPH::Dependency::File php files

=item C<< -E<gt>realpath() >> B<(internal)>

resolve directory traversal

=back

=head1 AUTHOR

the GPH::Dependency::AliceFixturesPlugin module was written by wicliff wolda <wicliff.wolda@gmail.com>

=head1 COPYRIGHT AND LICENSE

this library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut