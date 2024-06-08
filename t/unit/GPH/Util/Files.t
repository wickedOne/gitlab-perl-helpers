#!/usr/bin/perl
package t::unit::GPH::Util::Files;

use strict;
use warnings;

use Test2::V0 -target => 'GPH::Util::Files';
use Test2::Tools::Spec;

use Data::Dumper;

describe "class `$CLASS`" => sub {
    tests 'it can be instantiated' => sub {
        can_ok($CLASS, 'new');
    };

    tests 'instantiation' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new();
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');
    };
};

describe "class `$CLASS` segment method" => sub {
    my @files = [
        'tests/Unit/Parser/MapperTest.php',
        'tests/Functional/Parser/MapperTest.php',
        'tests/Functional/Parser/MapperTestCase.php',
    ];

    tests 'dies for with missing paths' => sub {
        ok(dies {$CLASS->new()->segment((max => 10, depth => 2))}, 'died with non existing directory') or note($@);
    };

    tests 'segment with default args' => sub {
        my ($object, $exception, $warnings, %segments);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new();
                %segments = $object->segment((paths => @files));
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            \%segments,
            hash {
                field tests => array {
                    item 'tests/Unit/Parser/MapperTest.php';
                    item 'tests/Functional/Parser/MapperTest.php';
                    item 'tests/Functional/Parser/MapperTestCase.php';
                    end;
                };
                end;
            },
                'object as expected'
        ) or diag Dumper(%segments);
    };

    tests 'segment with depth 2' => sub {
        my ($object, $exception, $warnings, %segments);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new();
                %segments = $object->segment((paths => @files, depth => 2));
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            \%segments,
            hash {
                field "tests.Unit" => array {
                    item 'tests/Unit/Parser/MapperTest.php';
                    end;
                };
                field "tests.Functional" => array {
                    item 'tests/Functional/Parser/MapperTest.php';
                    item 'tests/Functional/Parser/MapperTestCase.php';
                    end;
                };
                end;
            },
                'object as expected'
        ) or diag Dumper(%segments);
    };

    tests 'segment with depth 2 and max 1' => sub {
        my ($object, $exception, $warnings, %segments);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new();
                %segments = $object->segment((paths => @files, depth => 2, max => 1));
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            \%segments,
            hash {
                field "tests.Unit" => array {
                    item 'tests/Unit/Parser/MapperTest.php';
                    end;
                };
                field "tests.Functional" => array {
                    item 'tests/Functional/Parser/MapperTestCase.php';
                    end;
                };
                end;
                field "tests.Functional.1" => array {
                    item 'tests/Functional/Parser/MapperTest.php';
                    end;
                };
                end;
            },
            'object as expected'
        ) or diag Dumper(%segments);
    };

    tests 'segment with depth 2 and max 1 and segment max' => sub {
        my ($object, $exception, $warnings, %segments);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new();
                %segments = $object->segment((paths => @files, depth => 2, max => 1, segment_max => {'tests.Functional' => 2}));
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            \%segments,
            hash {
                field "tests.Unit" => array {
                    item 'tests/Unit/Parser/MapperTest.php';
                    end;
                };
                field "tests.Functional" => array {
                    item 'tests/Functional/Parser/MapperTest.php';
                    item 'tests/Functional/Parser/MapperTestCase.php';
                    end;
                };
                end;
            },
                'object as expected'
        ) or diag Dumper(%segments);
    };

    tests 'segment with depth 2, without max and segment max' => sub {
        my ($object, $exception, $warnings, %segments);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new();
                %segments = $object->segment((paths => @files, depth => 2, segment_max => {'tests.Unit' => 1}));
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            \%segments,
            hash {
                field "tests.Unit" => array {
                    item 'tests/Unit/Parser/MapperTest.php';
                    end;
                };
                field "tests.Functional" => array {
                    item 'tests/Functional/Parser/MapperTest.php';
                    item 'tests/Functional/Parser/MapperTestCase.php';
                    end;
                };
                end;
            },
                'object as expected'
        ) or diag Dumper(%segments);
    };
};

done_testing();

