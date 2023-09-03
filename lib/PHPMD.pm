#------------------------------------------------------------------------------
# File:         PHPMD.pm
#
# Description:  PHPMD related functions.
#               for now only generates phpmd config file with cyclomatic complexity rule
#
# Revisions:    2023-07-05 - created
#------------------------------------------------------------------------------

package PHPMD;

use strict;
use warnings FATAL => 'all';

use XML::LibXML;
use XMLHelper;

#------------------------------------------------------------------------------
# Construct new class
#
# Inputs:  0) string code owner
#          1) int maximum cyclomatic complexity level
#
# Returns: reference to PHPMD object
sub new {
    my ($class, $owner, $cycloLevel) = @_;

    my $self = {
        owner      => $owner,
        cycloLevel => $cycloLevel,
        generator  => XMLHelper->new(),
    };

    bless $self, $class;

    return $self;
}

#------------------------------------------------------------------------------
# Get config
#
# Returns: ruleset.xml config file string
sub GetConfig {
  my $self = shift;

  my $ruleset = $self->{generator}->BuildElement('ruleset', undef, undef, (
    'xmlns:xsi'                     => 'http://www.w3.org/2001/XMLSchema-instance',
    'xsi:schemaLocation'            => 'http://pmd.sf.net/ruleset/1.0.0 http://pmd.sf.net/ruleset_xml_schema.xsd',
    'xsi:noNamespaceSchemaLocation' => 'http://pmd.sf.net/ruleset_xml_schema.xsd',
    'name'                          => "$self->{owner} PHPMD rule set",
  ));

  $ruleset->setNamespace('http://pmd.sf.net/ruleset/1.0.0');

  my $rule = $self->{generator}->BuildElement('rule', undef, $ruleset, (
    'ref'                           => 'rulesets/codesize.xml/CyclomaticComplexity'
  ));

  my $properties = $self->{generator}->BuildElement('properties', undef, $rule);

  my $property = $self->{generator}->BuildElement('property', undef, $properties, (
    'name'                          => 'reportLevel',
    'value'                         => $self->{cycloLevel}
  ));

  my $dom = $self->{generator}->GetDom();
  $dom->setDocumentElement($ruleset);

  return ($dom->toString(1));
}

1;