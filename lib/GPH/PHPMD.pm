package GPH::PHPMD;

use strict;
use warnings FATAL => 'all';

use XML::LibXML;
use GPH::XMLHelper;

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

__END__

=head1 NAME

GPH::PHPMD - generate custom configuration file for L<PHP Mess Detector|https://phpmd.org/>

=head1 SYNOPSIS

    use GPH::PHPMD;

    my $phpmd = GPH::PHPMD->new((
        owner       => '@teams/alpha',
        cyclo_level => 5,
    ));

    print $phpmd->getConfig();

=head1 METHODS

=over 4

=item C<< -E<gt>new(%args) >>

the C<new> method creates a new GPH::PHPMD instance. it takes a hash of options, valid option keys include:

=over

=item owner B<(required)>

code owner name

=item cyclo_level B<(required)>

cyclomatic complexity level

=back

=item C<< -E<gt>getConfig() >>

returns configuration xml for PHPMD

=back

=head1 AUTHOR

the GPH::PHPMD module was written by wicliff wolda <wicliff.wolda@gmail.com>

=head1 COPYRIGHT AND LICENSE

this library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut