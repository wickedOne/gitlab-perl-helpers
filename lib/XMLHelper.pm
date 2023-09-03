#------------------------------------------------------------------------------
# File:         XMLHelper.pm
#
# Description:  XMLHelper simplifies creation of DOM elements
#
# Revisions:    2023-09-03 - created
#------------------------------------------------------------------------------

package XMLHelper;

use strict;
use warnings FATAL => 'all';

use XML::LibXML;

#------------------------------------------------------------------------------
# Construct new class
#
# Returns: reference to XMLHelper object
sub new {
    my ($class) = @_;

    my $self = {
        dom => XML::LibXML->createDocument('1.0', 'UTF-8'),
    };

    bless $self, $class;

    return $self;
}

#------------------------------------------------------------------------------
# Build element
#
# Inputs:  0) string: name of the element
#          1) mixed: value of the element
#          2) LibXML::Element object: parent element
#          3) list: element attributes
#
# Returns: LibXML::Element object
sub BuildElement {
  my ($self, $name, $value, $parent, %attributes) = @_;

  my $element = $self->{dom}->createElement($name);

  while (my ($attr, $value) = each %attributes) {
    if (defined $value) {
        $element->{$attr} = $value;
    }
  }

  if (defined $value) {
    $element->appendText($value);
  }

  if (defined $parent) {
    $parent->appendChild($element);
  }

  return $element;
}

#------------------------------------------------------------------------------
# Get DOM
#
# Returns: dom object
sub GetDom {
    my $self = shift;

    return $self->{dom};
}

1;