#------------------------------------------------------------------------------
# File:         GPH::XMLHelper.pm
#
# Description:  GPH::XMLHelper simplifies creation of DOM elements
#
# Revisions:    2023-09-03 - created
#               2024-02-10 - namespaced module, bugfixes and unit tests
#               2024-02-12 - constructor now requires named arguments
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
# Inputs:  name       => (string) name of the element
#          value      => (string) value of the element
#          parent     => (LibXML::Element object) parent element
#          attributes => (hash) element attributes
#
# Returns: LibXML::Element object
sub buildElement {
    my ($self, %args) = @_;

    (exists($args{name})) or die "$!";

    my $element = $self->{dom}->createElement($args{name});

    if (exists($args{attributes})) {
        foreach my $key (sort keys %{$args{attributes}}) {
            if (defined $args{attributes}{$key}) {
                $element->{$key} = $args{attributes}{$key};
            }
        }
    }

    if (defined $args{value}) {
        $element->appendText($args{value});
    }

    if (defined $args{parent}) {
        $args{parent}->appendChild($element);
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