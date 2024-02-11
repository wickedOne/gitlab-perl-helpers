#!/usr/bin/perl
package t::unit::GPH::PHPUnit::Stats;

use strict;
use warnings;

use Test2::V0 -target => 'GPH::PHPUnit::Stats';
use Test2::Tools::Spec;

use Data::Dumper;

local $SIG{__WARN__} = sub {};

my %config = (
    owner     => '@teams/alpha',
    threshold => 95.01
);

describe "class `$CLASS`" => sub {
    tests 'it can be instantiated' => sub {
        can_ok($CLASS, 'new');
    };

    tests "mandatory config options" => sub {
        ok(dies{$CLASS->new((threshold => '1'))}, 'died with missing owner option') or note ($@);
        ok(lives{$CLASS->new((owner => '@teams/alpha'))}, 'lives with mandatory options') or note ($@);
    };
};

describe 'configuration options' => sub {
    tests 'instantation' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new(%config);
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field owner => '@teams/alpha';
                field threshold => 95.01;
                field classes => object {
                    prop blessed => 'GPH::PHPUnit::Stat';
                };
                field methods => object {
                    prop blessed => 'GPH::PHPUnit::Stat';
                };
                field lines => object {
                    prop blessed => 'GPH::PHPUnit::Stat';
                };
                end;
            },
            'object as expected',
            Dumper($object)
        );
    };
};

describe 'class methods' => sub {
    my @output = (
        'Methods: 100.00% ( 4/ 4)   Lines: 100.00% ( 30/ 30)',
        'Methods: 100.00% ( 2/ 2)   Lines: 100.00% ( 13/ 13)',
        'Methods:  50.00% ( 1/ 2)   Lines:  76.92% ( 10/ 13)',
        'Methods: 100.00% ( 2/ 2)   Lines: 100.00% (  9/  9)',
        'Methods: 100.00% ( 5/ 5)   Lines: 100.00% ( 20/ 20)',
        'Methods:  80.00% ( 4/ 5)   Lines:  97.96% ( 48/ 49)',
        'Methods: 100.00% ( 3/ 3)   Lines: 100.00% ( 18/ 18)',
        'Methods: 100.00% ( 1/ 1)   Lines: 100.00% (  1/  1)',
    );

    tests 'test add method' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new(%config);

                for my $stats (@output) {
                    $object->add($stats);
                }
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is($object->{methods}->{total}, 24, 'total methods ok');
        is($object->{methods}->{covered}, 22, 'covered methods ok');
        is($object->{lines}->{total}, 153, 'total lines ok');
        is($object->{lines}->{covered}, 149, 'covered lines ok');
        is($object->{classes}->{total}, 8, 'total lines ok');
        is($object->{classes}->{covered}, 6, 'covered lines ok');
    };
};

describe "class method" => sub {
    my ($object, $exception, $warnings, $threshold, $expected_exit_code);

    case "coverage ok" => sub {
        $threshold = 95.0;
        $expected_exit_code = 0;
    };

    case "coverage not ok" => sub {
        $threshold = 100.0;
        $expected_exit_code = 1;
    };

    tests "test exit_code method" => sub {
        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((owner => '@teams/alpha', threshold => $threshold));
                $object->add('Methods:  80.00% ( 4/ 5)   Lines:  97.96% ( 48/ 49)');

            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');
        is($object->exitCode(), $expected_exit_code, 'exit code ok');
    };
};

describe "class method" => sub {
    my ($object, $exception, $warnings);

    tests "test summary method" => sub {
        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new(%config);
                $object
                    ->add('Methods:  80.00% ( 4/ 5)   Lines:  97.96% ( 48/ 49)')
                    ->add('Methods:  50.00% ( 1/ 2)   Lines:  76.92% ( 10/ 13)')
                ;
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        like($object->summary(), qr{Code Coverage Report for \@teams/alpha}, 'summary contains owner name');
        like($object->summary(), qr{[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}}, 'summary contains date time stamp');
        like($object->summary(), qr{Classes:[ ]+0\.00% \(0/2\)}, 'summary contains class coverage');
        like($object->summary(), qr{Methods:[ ]+71\.43% \(5/7\)}, 'summary contains method coverage');
        like($object->summary(), qr{Lines:[ ]+93\.55% \(58/62\)}, 'summary contains line coverage');
    };
};

describe "class method" => sub {
    my ($object, $exception, $warnings, $threshold, $expected_footer);

    case "coverage higher than threshold" => sub {
        $threshold = 95.0;
        $expected_footer = qr{! \[NOTE\] Your coverage is [0-9]+\.[0-9]{2}% percentage points over the required coverage};
    };

    case "coverage lower than threshold" => sub {
        $threshold = 100.0;
        $expected_footer = qr{! \[FAILED\] Your coverage is [0-9]+\.[0-9]{2}% percentage points under the required coverage};
    };

    tests "test footer method" => sub {
        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((owner => '@teams/alpha', threshold => $threshold));
                $object->add('Methods:  80.00% ( 4/ 5)   Lines:  97.96% ( 48/ 49)');

            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        like($object->footer(), $expected_footer, 'footer as expected');
    };
};

done_testing();
