#------------------------------------------------------------------------------
# File:         GPH::Psalm.pm
#
# Description:  psalm related functions.
#               for now only generate psalm config file
#
# Revisions:    2023-01-21 - created
#               2023-02-18 - ready for general usage
#               2023-07-05 - added baseline check config option
#               2023-08-30 - added config handler clone method
#               2023-09-03 - build config using lib xml
#               2024-02-10 - namespaced module, bugfixes and unit tests
#               2024-02-11 - constructor now requires named arguments
#------------------------------------------------------------------------------

package GPH::Psalm;

use strict;
use warnings FATAL => 'all';

use XML::LibXML;
use GPH::XMLHelper;

#------------------------------------------------------------------------------
# Construct new class
#
# Inputs:  level              => (string) psalm error level
#          paths              => (string) paths to analyse
#          baseline           => (string) path to baseline file, defaults to undef
#          baselineCheck      => (string) true|false used for setting the findUnusedBaselineEntry flag, defaults to true
#          ignoredDirectories => (array) ignored directories
#          cacheDir           => (string) path to cache directory, defaults to ./psalm
#          plugins            => (array) used plugins
#
# Returns: reference to GPH::Psalm object
sub new {
    my ($class, %args) = @_;

    (exists($args{level}) and exists($args{paths})) or die "$!";

    my $self = {
        level              => $args{level},
        paths              => $args{paths},
        ignoredDirectories => $args{ignoredDirectories} || undef,
        baseline           => $args{baseline} || undef,
        baselineCheck      => $args{baselineCheck} || 'true',
        cacheDir           => $args{cacheDir} || './psalm',
        plugins            => $args{plugins} || undef,
        generator          => GPH::XMLHelper->new(),
    };

    bless $self, $class;

    return $self;
}

#------------------------------------------------------------------------------
# Get config
#
# Returns: psalm.xml config file string
sub getConfig {
    my $self = shift;

    my $psalm = $self->{generator}->buildElement('psalm', undef, undef, (
        'resolveFromConfigFile'   => 'true',
        'xmlns:xsi'               => 'http://www.w3.org/2001/XMLSchema-instance',
        'xsi:schemaLocation'      => 'https://getpsalm.org/schema/config vendor/vimeo/psalm/config.xsd',
        'errorLevel'              => $self->{level},
        'cacheDirectory'          => $self->{cacheDir},
        'errorBaseline'           => $self->{baseline},
        'findUnusedBaselineEntry' => $self->{baselineCheck},
    ));

    $psalm->setNamespace('https://getpsalm.org/schema/config');

    my $projectFiles = $self->{generator}->buildElement('projectFiles', undef, $psalm);

    foreach my $path (@{$self->{paths}}) {
        $self->{generator}->buildElement('directory', undef, $projectFiles, (
            'name' => $path,
        ));
    }

    if (@{$self->{ignoredDirectories}}) {
        my $ignoreFiles = $self->{generator}->buildElement('ignoreFiles', undef, $projectFiles);

        foreach my $path (@{$self->{ignoredDirectories}}) {
            $self->{generator}->buildElement('directory', undef, $ignoreFiles, (
                'name' => $path,
            ));
        }
    }

    if (@{$self->{plugins}}) {
        my $plugins = $self->{generator}->buildElement('plugins', undef, $psalm);

        foreach my $plugin (@{$self->{plugins}}) {
            $self->{generator}->buildElement('pluginClass', undef, $plugins, (
                'class' => $plugin,
            ));
        }
    }

    my $dom = $self->{generator}->getDom();
    $dom->setDocumentElement($psalm);

    return ($dom->toString(1));
}

#------------------------------------------------------------------------------
# Get Config With Issue Handlers
# injects issue handlers from given psalm config file
#
# Returns: psalm.xml config file string
sub getConfigWithIssueHandlers {
    my ($self, $path, $blacklist) = @_;

    my $dom = XML::LibXML->load_xml(location => $path);
    my $config = XML::LibXML->load_xml(string => $self->getConfig());

    my ($handlers) = $dom->findnodes('//*[local-name()="issueHandlers"]');

    foreach my $exclude ($blacklist) {
        my ($remove) = $handlers->findnodes("//*[local-name()=\"${exclude}\"]");

        if (defined $remove) {
            $handlers->removeChild($remove);
        }
    }

    $config->documentElement->appendChild($handlers);

    return ($config->toString());
}

1;