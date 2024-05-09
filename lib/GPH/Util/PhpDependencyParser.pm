package GPH::Util::PhpDependencyParser;

use strict;
use warnings FATAL => 'all';

use File::Find::Rule;
use Cwd;

sub new {
    my ($proto) = @_;

    return bless {
        'usages'      => {},
        'traits'      => {},
        'abstracts'   => {},
        'inheritance' => {},
        'classmap'    => {},
    }, $proto;
}

sub dir {
    my ($self, $dir, $strip) = @_;

    my @files = File::Find::Rule->file()
        ->name('*.php')
        ->in($dir)
    ;

    foreach my $file (@files) {
        $self->parse($file, $strip);
    }

    return ($self);
}

sub parse {
    my ($self, $path, $strip) = @_;
    my ($fh, $class, $namespace, @usages, %aliases, $fqcn);

    return $self unless $path =~ '[/]{0,}([^/]+)\.php$';

    open($fh, '<', $path) or die "unable to open file $path : $!";

    $class = $1;

    $path =~ s/$strip//g;

    while (<$fh>) {
        chomp $_;

        next if $_ =~ /^[\* ]\*/ or $_ eq '';

        # collect usages
        if ($_ =~ /^use ([^ ;]+).*$/) {
            next if $_ =~ /^use function .*$/;

            $self->{usages}{$1} = [] unless defined $self->{usages}{$1};
            push(@usages, $1);

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
            my @matches = grep(/$meta/, @usages);

            if (defined $aliases{$1}) {
                $fqcn = $aliases{$1};
            }
            elsif (defined $matches[0]) {
                $fqcn = $matches[0];
            }
            else {
                $fqcn = $namespace . '\\' . $1;
            }

            $self->{inheritance}{$namespace . '\\' . $class} = {
                extends => $fqcn,
                usages  => \@usages,
                file    => $path,
            };
        }

        # define class type (class, trait, enum, etc.)
        if ($_ =~ "[ ]{0,}([^ ]+) $class(?:[ :]|\$){1,}") {
            $fqcn = $namespace . '\\' . $class;
            $self->{classmap}{$path} = $fqcn;

            if ($_ =~ "^abstract class $class" || $class =~ /.*TestCase$/) {
                $self->{abstracts}{$fqcn} = \@usages;
            }
            elsif (defined $1 && $1 eq 'trait') {
                $self->{traits}{$fqcn} = \@usages;
            }
            else {
                foreach my $dep (@usages) {
                    push(@{$self->{usages}{$dep}}, $path);
                }
            }

            last;
        }
    }

    close($fh);

    return ($self);
}

sub inheritance {
    my ($self) = @_;

    foreach my $class (keys %{$self->{inheritance}}) {
        my $parent = $self->{inheritance}{$class}{extends};

        while (defined $self->{inheritance}{$parent}) {
            foreach my $dependency (@{$self->{inheritance}{$parent}{usages}}) {
                push(@{$self->{usages}{$dependency}}, $self->{inheritance}{$class}{file});
            }

            $parent = $self->{inheritance}{$parent}{extends};
        }
    }
    return ($self);
}

sub traits {
    my ($self) = @_;

    foreach my $trait (keys %{$self->{traits}}) {
        next unless defined $self->{usages}{$trait};

        foreach my $path (@{$self->{usages}{$trait}}) {
            foreach my $dependency (@{$self->{traits}{$trait}}) {
                push(@{$self->{usages}{$dependency}}, $path);
            }
        }
    }

    return ($self);
}

sub sanitise {
    my ($self) = @_;
    my $key;

    foreach $key (keys %{$self->{abstracts}}) {
        delete $self->{usages}{$key};
    }
    foreach $key (keys %{$self->{traits}}) {
        delete $self->{usages}{$key};
    }

    return ($self);
}

sub filter {
    my ($self, %args) = @_;
    my (@result, @namespaces, @out);

    (exists($args{collection}) && exists($args{in}) && exists($args{out})) or die "$!";

    @namespaces = ($args{in} eq 'namespaces') ? @{$args{collection}} : $self->namespaces(@{$args{collection}});

    foreach my $namespace (@namespaces) {
        push(@result, @{$self->{usages}{$namespace}}) unless !defined $self->{usages}{$namespace};
    }

    my @unique = do {
        my %seen;
        grep {!$seen{$_}++} @result
    };

    @out = ($args{out} eq 'files') ? @unique : $self->namespaces(@unique);

    return (sort @out);
}

sub namespaces {
    my ($self, @files) = @_;
    my @result;

    foreach my $filename (@files) {
        push(@result, $self->{classmap}{$filename}) unless !defined $self->{classmap}{$filename};
    }

    return(@result);
}

1;

__END__

=head1 NAME

GPH::Util::PhpDependencyParser - parses one or more php files and builds a dependency map

=head1 SYNOPSIS

    use GPH::Util::PhpDependencyParser;

    my $config = GPH::PHPUnit::Config->new()
        ->dir('/Users/foo/Code/bar/tests/', '/Users/foo/Code/bar/')
    ;

    print $parser->filter(['App\Service\Provider\FooProvider.php');

=head1 METHODS

=over 4

=item C<< -E<gt>new() >>

the C<new> method creates a new GPH::Util::PhpDependencyParser.

=item C<< -E<gt>dir($directory, $strip) >>

scans and builds a dependency map from all php files in C< $directory >. the resulting paths will be stripped of the
prefix defined in C<$strip>

=item C<< -E<gt>parse($filepath, $strip) >>

scans and builds a dependency map the php file defined in C<$filepath>. the resulting paths will be stripped of the
prefix defined in C<$strip>

returns reference to the parsed classmap hash.

=item C<< -E<gt>inheritance() >>

enriches the dependency map by processing the php dependency graph.

=item C<< -E<gt>traits() >>

enriches the dependency map by processing traits.

=item C<< -E<gt>sanitise() >>

removes abstract classes and traits from the dependency map.

=item C<< -E<gt>filter(%args) >>

returns an array of file paths or namespaces which have a dependency on given collection. it takes a hash of options, valid option keys include:

=over

=item collection B<(required)>

an array of either file paths or namespaces for which you want dependencies

=item in B<(required)>

type of collection provided. valid values are "namespaces" and "files"

=item out B<(required)>

type of collection required. valid values are "namespaces" and "files"

=back

=item C<< -E<gt>namespaces(@files) >> B<(internal)>

returns an array of namespaces for given C<@files>.

=back

=head1 AUTHOR

the GPH::Util::PhpDependencyParser module was written by wicliff wolda <wicliff.wolda@gmail.com>

=head1 COPYRIGHT AND LICENSE

this library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut