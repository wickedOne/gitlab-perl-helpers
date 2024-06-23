package GPH::Dependency::PhpDependencyPlugin;

use strict;
use warnings FATAL => 'all';

use GPH::Dependency::File;
use File::Find::Rule;

sub new {
    my ($proto, %args) = @_;

    (exists($args{directories}) && exists($args{strip})) or die "$!";

    my $self = bless {
        directories => $args{directories},
        excludes    => $args{excludes} // undef,
        strip       => $args{strip},
        files       => {},
    }, $proto;

    return ($self);
}

sub files {
    my ($self) = @_;

    $self
        ->dir()
    ;

    return ($self->{'files'});
};

sub dir {
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
        $self->parse($file);
    }

    return ($self);
}

sub parse {
    my ($self, $path) = @_;
    my ($fh, $class, $namespace, %usages, %aliases, $extends, $type);

    return $self unless $path =~ '[/]{0,}([^/]+)\.php$';

    open($fh, '<', $path) or die "unable to open file $path : $!";

    $class = $1;

    $path =~ s/$self->{strip}//g;

    while (<$fh>) {
        chomp $_;

        next if $_ =~ /^[\s]{0,}[\/]{0,1}[\*]{1,2}/ or $_ eq '' or $_ =~ /^[\s]*\/\//;

        # collect usages
        if ($_ =~ /^use ([^ ;]+).*$/) {
            next if $_ =~ /^use function .*$/;

            $usages{$1} = 1;

            # register aliases
            if ($_ =~ /^use ([^ ]+) as ([^;]+);/) {
                $aliases{$2} = $1;
            }

            next;
        }

        # get namespace
        if ($_ =~ /^namespace (.*);$/) {
            $namespace = $1;

            next;
        }

        # process inheritance
        if ($_ =~ /$class\s*extends\s*([^ ]+)/) {
            my $meta = quotemeta($1);
            my @matches = grep(/$meta/, keys %usages);

            if (defined $aliases{$1}) {
                $extends = $aliases{$1};
            }
            elsif (defined $matches[0]) {
                $extends = $matches[0];
            }
            else {
                $extends = $namespace . '\\' . $1;
                $usages{$extends} = 1;
            }
        }

        $type = 'class';

        # define class type (class, trait, enum, etc.)
        if ($_ =~ "[ ]{0,}([^ ]+) $class(?:[ :]|\$){1,}") {
            $type = $1;

            if ($_ =~ "^abstract class $class" || $class =~ /.*TestCase$/) {
                $type = 'abstract';
            }

            $self->{files}{$path} = GPH::Dependency::File->new((
                type         => $type,
                file         => $path,
                fqcn         => $namespace . '\\' . $class,
                dependencies => \%usages,
                extends      => $extends // undef,
            ));

            last;
        }
    }

    close($fh);

    return ($self);
}

1;

__END__

=head1 NAME

GPH::Dependency::PhpDependencyPlugin - a GPH::Dependency::DependencyMapBuilder plugin which extracts php dependencies.

=head1 SYNOPSIS

    use GPH::Dependency::PhpDependencyPlugin;

    my $php = GPH::Dependency::PhpDependencyPlugin->new((
        strip       => '/Users/foo/',
        directories => [
            '/Users/foo/tests/Functional',
            '/Users/foo/tests/Unit'
        ],
        excludes    => [ '/Users/foo/tests/Functional/Bar' ]
    ));

    my $php = $fixtures->files();

=head1 METHODS

=over 4

=item C<< -E<gt>new(%args) >>

the C<new> method creates a new GPH::Dependency::PhpDependencyPlugin. it takes a hash of options, valid option keys include:

=over

=item directories B<(required)>

array of paths of directories containing php files using fixtures.

=item strip B<(required)>

string defining which bit should be stripped of the filepath

=item excludes

array of paths of directories containing php files which to ignore.

=back

=item C<< -E<gt>files() >>

parse php files, define and resolve dependencies and return a collection of GPH::Dependency::File objects.

=item C<< -E<gt>dir() >> B<(internal)>

iterate over php files contained in the C<$self->{directories}> property.

=item C<< -E<gt>parse($file) >> B<(internal)>

parse php file located at filepath $file, define and resolve it's fixture dependencies.

=back

=head1 AUTHOR

the GPH::Dependency::PhpDependencyPlugin module was written by wicliff wolda <wicliff.wolda@gmail.com>

=head1 COPYRIGHT AND LICENSE

this library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut