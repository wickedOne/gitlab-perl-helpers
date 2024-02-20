package GPH::XMLHelper;

use strict;
use warnings FATAL => 'all';

use XML::LibXML;

sub new {
    my ($class) = @_;

    my $self = {
        dom => XML::LibXML->createDocument('1.0', 'UTF-8'),
    };

    bless $self, $class;

    return $self;
}

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

sub getDom {
    my $self = shift;

    return $self->{dom};
}

1;

__END__

=head1 NAME

GPH::XMLHelper - helper class for creating xml nodes

=head1 SYNOPSIS

    use GPH::XMLHelper;

    my $helper = GPH::XMLHelper->new();

=head1 METHODS

=over 4

=item C<< -E<gt>new() >>

the C<new> method returns a GPH::XMLHelper object.

=item C<< -E<gt>buildElement(%args) >>

creates new XML::LibXML::Element instance. it takes a hash of options, valid option keys include:

=over

=item name B<(required)>

element name

=item attributes

element attributes

=item value

element value

=item parent

parent XML::LibXML::Element

=back

=item C<< -E<gt>getDom() >>

returns the DOM document.

=back

=head1 AUTHOR

the GPH::XMLHelper module was written by wicliff wolda <wicliff.wolda@gmail.com>

=head1 COPYRIGHT AND LICENSE

this library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut