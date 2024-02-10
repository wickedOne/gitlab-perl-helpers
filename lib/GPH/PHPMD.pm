#------------------------------------------------------------------------------
# File:         GPH::PHPMD.pm
#
# Description:  GPH::PHPMD related functions.
#               for now only generates phpmd config file with cyclomatic complexity rule
#
# Revisions:    2023-07-05 - created
#               2024-02-10 - namespaced module, bugfixes and unit tests
#------------------------------------------------------------------------------

package GPH::PHPMD;

use strict;
use warnings FATAL => 'all';

use XML::LibXML;
use GPH::XMLHelper;

#------------------------------------------------------------------------------
# Construct new class
#
# Inputs:  0) string code owner
#          1) int maximum cyclomatic complexity level
#
# Returns: reference to GPH::PHPMD object
sub new {
    my ($class, $owner, $cycloLevel) = @_;

    my $self = {
        owner      => $owner,
        cycloLevel => $cycloLevel,
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

  my $ruleset = $self->{generator}->buildElement('ruleset', undef, undef, (
    'xmlns:xsi'                     => 'http://www.w3.org/2001/XMLSchema-instance',
    'xsi:schemaLocation'            => 'http://pmd.sf.net/ruleset/1.0.0 http://pmd.sf.net/ruleset_xml_schema.xsd',
    'xsi:noNamespaceSchemaLocation' => 'http://pmd.sf.net/ruleset_xml_schema.xsd',
    'name'                          => "$self->{owner} PHPMD rule set",
  ));

  $ruleset->setNamespace('http://pmd.sf.net/ruleset/1.0.0');

  my $rule = $self->{generator}->buildElement('rule', undef, $ruleset, (
    'ref'                           => 'rulesets/codesize.xml/CyclomaticComplexity'
  ));

  my $properties = $self->{generator}->buildElement('properties', undef, $rule);

  $self->{generator}->buildElement('property', undef, $properties, (
    'name'                          => 'reportLevel',
    'value'                         => $self->{cycloLevel}
  ));

  my $dom = $self->{generator}->getDom();

  $dom->setDocumentElement($ruleset);

  return ($dom->toString(1));
}

1;