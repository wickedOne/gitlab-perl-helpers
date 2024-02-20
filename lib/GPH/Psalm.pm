package GPH::Psalm;

use strict;
use warnings FATAL => 'all';

use XML::LibXML;
use GPH::XMLHelper;

sub new {
    my ($class, %args) = @_;

    (exists($args{level}) and exists($args{paths})) or die "$!";

    # prevent empty arrays
    my $ignored = ((defined($args{ignored_directories}) and scalar(@{$args{ignored_directories}}) != 0) ? $args{ignored_directories} : undef);
    my $plugins = ((defined($args{plugins}) and scalar(@{$args{plugins}}) != 0) ? $args{plugins} : undef);

    my $self = {
        level               => $args{level},
        paths               => $args{paths},
        ignored_directories => $ignored,
        baseline            => $args{baseline} || undef,
        baseline_check      => $args{baseline_check} || 'true',
        cache_dir           => $args{cache_dir} || './psalm',
        plugins             => $plugins,
        generator           => GPH::XMLHelper->new(),
    };

    bless $self, $class;

    return $self;
}

sub getConfig {
    my $self = shift;
    my $type;

    my $psalm = $self->{generator}->buildElement((name => 'psalm', attributes => {
        'resolveFromConfigFile'   => 'true',
        'xmlns:xsi'               => 'http://www.w3.org/2001/XMLSchema-instance',
        'xsi:schemaLocation'      => 'https://getpsalm.org/schema/config vendor/vimeo/psalm/config.xsd',
        'errorLevel'              => $self->{level},
        'cacheDirectory'          => $self->{cache_dir},
        'errorBaseline'           => $self->{baseline},
        'findUnusedBaselineEntry' => $self->{baseline_check},
    }));

    $psalm->setNamespace('https://getpsalm.org/schema/config');

    my $projectFiles = $self->{generator}->buildElement((name => 'projectFiles', parent => $psalm));

    foreach my $path (@{$self->{paths}}) {
        $type = ($path =~ /.*\.[a-z]{2,}$/) ? 'file' : 'directory';

        $self->{generator}->buildElement((name => $type, parent => $projectFiles, attributes => {
            'name' => $path,
        }));
    }

    if (defined $self->{ignored_directories}) {
        my $ignoreFiles = $self->{generator}->buildElement((name => 'ignoreFiles', parent => $projectFiles));

        foreach my $path (@{$self->{ignored_directories}}) {
            $type = ($path =~ /.*\.[a-z]{2,}$/) ? 'file' : 'directory';

            $self->{generator}->buildElement((name => $type, parent => $ignoreFiles, attributes => {
                'name' => $path,
            }));
        }
    }

    if (defined $self->{plugins}) {
        my $plugins = $self->{generator}->buildElement((name => 'plugins', parent => $psalm));

        foreach my $plugin (@{$self->{plugins}}) {
            $self->{generator}->buildElement((name => 'pluginClass', parent => $plugins, attributes => {
                'class' => $plugin,
            }));
        }
    }

    my $dom = $self->{generator}->getDom();

    $dom->setDocumentElement($psalm);

    return ($dom->toString(1));
}

sub getConfigWithIssueHandlers {
    my ($self, $path, @blacklist) = @_;

    my $dom = XML::LibXML->load_xml(location => $path);
    my $config = XML::LibXML->load_xml(string => $self->getConfig());

    my ($handlers) = $dom->findnodes('//*[local-name()="issueHandlers"]');

    foreach my $exclude (@blacklist) {
        next unless defined $exclude;

        my ($remove) = $handlers->findnodes("//*[local-name()=\"${exclude}\"]");

        if (defined $remove) {
            $handlers->removeChild($remove);
        }
    }

    $config->documentElement->appendChild($handlers);

    return ($config->toString());
}

1;

__END__

=head1 NAME

GPH::Psalm - generate custom configuration file for L<Psalm|https://psalm.dev/>

=head1 SYNOPSIS

    use GPH::Psalm;

    my $psalm = GPH::Psalm->new((
        level => 6,
        paths => ['src/', 'tests/'],
    ));

    print $psalm->getConfig();

=head1 METHODS

=over 4

=item C<< -E<gt>new(%args) >>

the C<new> method creates a new GPH::Psalm instance. it takes a hash of options, valid option keys include:

=over

=item level B<(required)>

psalm analysis level

=item paths B<(required)>

paths to scan for analysis

=item ignored_directories

paths to ignore for analysis

=item baseline

path to baseline file

=item baseline_check

whether or not to scan for unused items in the baseline file. possible values are 'true' and 'false'

=item cache_dir

path to cache directory. defaults to '.psalm/'

=item plugins

paths with plugin names to be included in the config.

please note that additional plugin configuration is not supported by this module.

=back

=item C<< -E<gt>getConfig() >>

returns configuration xml for Psalm

=item C<< -E<gt>getConfigWithIssueHandlers($path, @excludes) >>

merges an issue handler section from another psalm configuration and returns the result.

    my $psalm = GPH::Psalm->new((
        level => 6,
        paths => ['src/', 'tests/'],
    ));

    print $psalm->getConfigWithIssueHandlers('psalm.xml', ['MoreSpecificImplementedParamType']);

the C<$path> parameter should define the path to the config file from which to clone the config handlers,
while the C<@excludes> list contains the names of issue handlers to ignore.

=back

=head1 AUTHOR

the GPH::PHPStan module was written by wicliff wolda <wicliff.wolda@gmail.com>

=head1 COPYRIGHT AND LICENSE

this library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut