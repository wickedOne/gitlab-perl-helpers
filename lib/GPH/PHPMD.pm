#------------------------------------------------------------------------------
# File:         GPH::PHPMD.pm
#
# Description:  GPH::PHPMD related functions.
#               for now only generates phpmd config file with cyclomatic complexity rule
#
# Revisions:    2023-07-05 - created
#               2024-02-10 - namespaced module, bugfixes and unit tests
#               2024-02-11 - constructor now requires named arguments
#------------------------------------------------------------------------------

package GPH::PHPMD;

use strict;
use warnings FATAL => 'all';

use XML::LibXML;
use GPH::XMLHelper;

#------------------------------------------------------------------------------
# Construct new class
#
# Inputs:  owner       => (string) code owner
#          cyclo_level => (int) maximum cyclomatic complexity level
#
# Returns: reference to GPH::PHPMD object
sub new {
    my ($class, %args) = @_;

    (exists($args{owner}) and exists($args{cyclo_level})) or die "$!";

    my $self = {
        owner      => $args{owner},
        cycloLevel => $args{cyclo_level},
        generator  => GPH::XMLHelper->new(),
    };

    bless $self, $class;

    return $self;
}

#------------------------------------------------------------------------------
# Get config
#
# Returns: ruleset.xml config file string
sub getConfig {
    my $self = shift;

    my $ruleset = $self->{generator}->buildElement((name => 'ruleset', attributes => {
        'xmlns:xsi'                     => 'http://www.w3.org/2001/XMLSchema-instance',
        'xsi:schemaLocation'            => 'http://pmd.sf.net/ruleset/1.0.0 http://pmd.sf.net/ruleset_xml_schema.xsd',
        'xsi:noNamespaceSchemaLocation' => 'http://pmd.sf.net/ruleset_xml_schema.xsd',
        'name'                          => "$self->{owner} PHPMD rule set",
    }));

    $ruleset->setNamespace('http://pmd.sf.net/ruleset/1.0.0');

    my $rule = $self->{generator}->buildElement((name => 'rule', parent => $ruleset, attributes => {
        'ref' => 'rulesets/codesize.xml/CyclomaticComplexity'
    }));

    my $properties = $self->{generator}->buildElement((name => 'properties', parent => $rule));

    $self->{generator}->buildElement((name => 'property', parent => $properties, attributes => {
        'name'  => 'reportLevel',
        'value' => $self->{cycloLevel}
    }));

    my $dom = $self->{generator}->getDom();

    $dom->setDocumentElement($ruleset);

    return ($dom->toString(1));
}

1;