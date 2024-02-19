#!/usr/bin/perl
package t::unit::GPH::PHPUnit::Stat;

use strict;
use warnings;

use Test2::V0 -target => 'GPH::PHPUnit::Stat';
use Test2::Tools::Spec;

use Data::Dumper;

describe "class `$CLASS`" => sub {
    tests 'it can be instantiated' => sub {
        can_ok($CLASS, 'new');
    };
};

describe "class `$CLASS` tests" => sub {
    my ($covered, $total, $expected_percentage, $expected_coverage, $name);

    case "no total, foo coverage name" => sub {
        $covered = 0;
        $total = 0;
        $expected_percentage = 0;
        $name = 'foo';
        $expected_coverage = '  Foo:     0.00% (0/0)';
    };

    case "has total, longer coverage name" => sub {
        $covered = 1;
        $total = 3;
        $expected_percentage = 33.33;
        $name = 'foo bar';
        $expected_coverage = '  Foo bar: 33.33% (1/3)';
    };

    tests "methods tests" => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new();
                $object->add($covered, $total);
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');
        is($expected_percentage, float($object->percentage(), precision => 2), 'percentage method call ok');
        is($object->coverage($name), $expected_coverage, 'coverage method call ok');
    };
};

done_testing();

