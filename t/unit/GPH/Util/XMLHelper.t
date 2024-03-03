#!/usr/bin/perl
package t::unit::GPH::Util::XMLHelper;

use strict;
use warnings;

use Test2::V0 -target => 'GPH::Util::XMLHelper';
use Test2::Tools::Spec;
use Data::Dumper;

describe "class `$CLASS`" => sub {
    tests 'it can be instantiated' => sub {
        can_ok($CLASS, 'new');
    };

    tests "mandatory element options" => sub {
        my $object = $CLASS->new();

        ok(dies {$object->buildElement((attributes => {}))}, 'died with missing name') or note($@);
        ok(lives {$object->buildElement((name => 'foo'))}, 'lives with mandatory options') or note($@);
    };

    tests 'object validation' => sub {
        my ($object, $exception, $warnings);
        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new();
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');
        is(
            $object,
            object {
                field dom => object {
                    prop blessed => 'XML::LibXML::Document';
                };
            },
                'object as expected',
                Dumper($object)
        );

    };
};

describe 'test element' => sub {
    my (%args, $element, $expected_xml);

    case 'name value attributes' => sub {
        %args = (
            name       => 'foo',
            value      => 'bar',
            attributes => {
                'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                'foo'       => undef
            }
        );
        $expected_xml = '<foo xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">bar</foo>';
    };

    case 'name' => sub {
        %args = (
            name => 'foo',
        );
        $expected_xml = '<foo/>';
    };

    case 'name value' => sub {
        %args = (
            name  => 'foo',
            value => 'bar',
        );
        $expected_xml = '<foo>bar</foo>';
    };

    tests 'element generation' => sub {
        my ($object, $exception, $warnings);
        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new();
                $element = $object->buildElement(%args);
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $element->toString(),
            $expected_xml,
            'element as expected',
            Dumper($element)
        );
    };
};

describe 'test parent element' => sub {
    my ($object, $dom, $element, $exception, $warnings);

    tests 'element generation' => sub {
        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new();
                $element = $object->buildElement((
                    name       => 'foo',
                    attributes => {
                        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance'
                    }
                ));

                $object->buildElement((
                    name   => 'bar',
                    parent => $element,
                    value  => 'baz',
                ));

                $dom = $object->getDom();
                $dom->setDocumentElement($element);
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $dom->toString(),
            '<?xml version="1.0" encoding="UTF-8"?>
<foo xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><bar>baz</bar></foo>
',
            'parent child element as expected',
            Dumper($dom->toString())
        )
    }
};

done_testing();

