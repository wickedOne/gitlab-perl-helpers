package GPH::PHPUnit::Config;

use strict;
use warnings FATAL => 'all';

use GPH::Util::XMLHelper;

sub new {
    my ($proto, %args) = @_;

    my $self = bless {
        config    => undef,
        generator => GPH::Util::XMLHelper->new(),
    }, $proto;

    my %defaults = (
        'xmlns:xsi'                     => 'http://www.w3.org/2001/XMLSchema-instance',
        'xsi:noNamespaceSchemaLocation' => 'phpunit.xsd',
    );

    my %input = ();

    if (exists($args{attributes}) && ref($args{attributes}) eq 'HASH') {
        %input = %{$args{attributes}};
    }

    my %attributes = (%defaults, %input);

    $self->{config} = $self->{generator}->buildElement((name => 'phpunit', attributes => \%attributes));

    return $self;
}

sub php {
    my ($self, %config) = @_;
    my ($key, $attributes, $size);
    $size = keys %config;

    if ($size == 0) {
        return($self);
    }

    my $phpunit = $self->{config};

    my $php = $self->{generator}->buildElement((name => 'php', parent => $phpunit));

    foreach $key (keys %config) {
        foreach $attributes (@{$config{$key}}) {
            $self->{generator}->buildElement((name => $key, attributes => \%{$attributes}, parent => => $php));
        }
    }

    return ($self);
}

sub testsuites {
    my ($self, %config) = @_;
    my $size = keys %config;

    if ($size == 0) {
        return($self);
    }

    my $phpunit = $self->{config};

    my $testsuites = $self->{generator}->buildElement((name => 'testsuites', parent => $phpunit));

    foreach my $suite (keys %config) {
        my $testsuite = $self->{generator}->buildElement((name => 'testsuite', attributes => { 'name' => $suite }, parent => $testsuites));

        foreach my $path (@{$config{$suite}}) {
            next if $path =~ /.*TestCase\.php/;
            my $type = ($path =~ /.*\.[a-z]{2,}$/) ? 'file' : 'directory';

            $self->{generator}->buildElement((name => $type, parent => $testsuite, value => $path));
        }
    }

    return $self;
}

sub extensions {
    my ($self, @config) = @_;
    my $size = @config;

    if ($size == 0) {
        return($self);
    }

    my $phpunit = $self->{config};

    my $extensions = $self->{generator}->buildElement((name => 'extensions', parent => $phpunit));

    foreach my $extension (@config) {
        $self->{generator}->buildElement((name => 'bootstrap', parent => $extensions, attributes => { class => $extension }));
    }

    return $self;
}

sub source {
    my ($self, %config) = @_;
    my $size = keys %config;

    if ($size == 0) {
        return($self);
    }

    my $phpunit = $self->{config};

    my $source = $self->{generator}->buildElement((name => 'source', parent => $phpunit));

    foreach my $element (keys %config) {
        my $sub = $self->{generator}->buildElement((name => $element, parent => $source));

        foreach my $path (@{$config{$element}}) {
            my $type = ($path =~ /.*\.[a-z]{2,}$/) ? 'file' : 'directory';

            if ($type eq 'file') {
                $self->{generator}->buildElement((name => $type, parent => $sub, value => $path));
            }
            else {
                $self->{generator}->buildElement((name => $type, parent => $sub, value => $path, attributes => { suffix => '.php' }));
            }
        }
    }

    return $self;
}

sub getConfig {
    my $self = shift;

    my $dom = $self->{generator}->getDom();

    $dom->setDocumentElement($self->{config});

    return ($dom->toString(1));
}

1;

__END__

=head1 NAME

GPH::PHPUnit::Config - generates phpunit ^10.5 config xml

=head1 SYNOPSIS

    use GPH::PHPUnit::Config;

    my %attributes = (
        'bootstrap'                     => 'tests/bootstrap.php',
        'cacheDirectory'                => '.phpunit.cache',
        'xsi:noNamespaceSchemaLocation' => 'https://schema.phpunit.de/10.5/phpunit.xsd',
    );

    my $builder = GPH::Util::PhpDependencyParser->new((attributes => \%attributes));

    print $builder->getConfig();

=head1 METHODS

=over 4

=item C<< -E<gt>new(%args) >>

the C<new> method creates a new GPH::PHPUnit::Config. it takes a hash of options, valid option keys include:

=over

=item attributes

a hash of attributes to add to the root element of the resulting xml

=back

=item C<< -E<gt>php(%config) >>

adds php section to the config file. it takes a C<%config> hash containing arrays of hashes.

=item C<< -E<gt>testsuites(%config) >>

adds testsuites section to the config file. it takes a C<%config> hash where the keys define the testsuite name and the array value
contains a list of files or directories which should be added to the test suite.

=item C<< -E<gt>extensions(@extensions) >>

adds a extensions section to the config file. it takes a C<@extensions> array of extension namespaces to add.

=item C<< -E<gt>source(%config) >>

adds a source section to the config file. it takes a C<%config> hash of arrays

=item C<< -E<gt>getConfig() >>

returns the xml config file as string.

=back

=head1 AUTHOR

the GPH::Util::PhpDependencyParser module was written by wicliff wolda <wicliff.wolda@gmail.com>

=head1 COPYRIGHT AND LICENSE

this library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut