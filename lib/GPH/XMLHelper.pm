#------------------------------------------------------------------------------
# File:         GPH::XMLHelper.pm
#
# Description:  GPH::XMLHelper simplifies creation of DOM elements
#
# Revisions:    2023-09-03 - created
#               2024-02-10 - namespaced module, bugfixes and unit tests
#------------------------------------------------------------------------------

package GPH::XMLHelper;

use strict;
use warnings FATAL => 'all';

use XML::LibXML;

#------------------------------------------------------------------------------
# Construct new class
#
# Returns: reference to GPH::XMLHelper object
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
sub buildElement {
  my ($self, $name, $value, $parent, %attributes) = @_;

  my $element = $self->{dom}->createElement($name);

  foreach my $key (sort keys %attributes) {
    if (defined $attributes{$key}) {
        $element->{$key} = $attributes{$key};
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
sub getDom {
    my $self = shift;

    return $self->{dom};
}

1;