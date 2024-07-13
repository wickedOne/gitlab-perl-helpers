#!/usr/bin/perl
package t::unit::GPH::PHPUnit::Teared;

use strict;
use warnings;

use Test2::V0 -target => 'GPH::PHPUnit::Teared';
use Test2::Tools::Spec;

use Data::Dumper;

describe "class `$CLASS` instantiation" => sub {
    tests 'it can be instantiated' => sub {
        can_ok($CLASS, 'new');
    };

    tests "mandatory config options" => sub {
        ok(dies {$CLASS->new()}, 'died with missing file option') or note($@);
    };

    tests 'instantiation with default values' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((file => 'foo.php'));
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field file => 'foo.php';
                field teardown => 0;
                field properties => hash {
                    end;
                };
                field teared => hash {
                    end;
                };
                end;
            },
            'object as expected',
            Dumper($object)
        );
    };

    tests 'instantiation with given values' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((
                    file       => 'foo.php',
                    teardown   => 1,
                    properties => { 'foo' => 1 },
                    teared     => { 'foo' => 1 },
                ));
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field file => 'foo.php';
                field teardown => 1;
                field properties => hash {
                    field 'foo' => 1;
                    end;
                };
                field teared => hash {
                    field 'foo' => 1;
                    end;
                };
                end;
            },
            'object as expected',
            Dumper($object)
        );
    };
};

describe "class `$CLASS` is valid method without teardown" => sub {
    tests 'invalid no teardown' => sub {
        my ($object, $exception, $warnings, $stdout);

        $exception = dies {
            $warnings = warns {
                local *STDOUT;

                open *STDOUT, '>', \$stdout;

                $object = $CLASS->new((
                    file       => 'foo.php',
                    teardown   => 0,
                    properties => { 'foo' => 1 },
                ))->isValid();

                close *STDOUT;
                chomp $stdout;
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is($object, 0, 'file is not valid') or diag Dumper($object);
        is($stdout, 'file foo.php is invalid: has properties, but no teardown', 'stdout correct') or diag Dumper($stdout);
    };
};

describe "class `$CLASS` is valid method without teared down properties" => sub {
    my ($object, $exception, $warnings, $stdout, %properties, $output);

    case 'single property' => sub {
        %properties = (
            foo => 1,
        );
        $output = 'file foo.php is invalid: property \'foo\' is not teared down';
    };

    case 'multiple properties' => sub {
        %properties = (
            foo => 1,
            bar => 1,
        );
        $output = 'file foo.php is invalid: properties \'bar\', \'foo\' are not teared down';
    };

    tests 'invalid properties not touched' => sub {
        $exception = dies {
            $warnings = warns {
                local *STDOUT;

                open *STDOUT, '>', \$stdout;

                $object = $CLASS->new((
                    file       => 'foo.php',
                    teardown   => 1,
                    properties => \%properties,
                ))->isValid();

                close *STDOUT;
                chomp $stdout;
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is($object, 0, 'file is not valid') or diag Dumper($object);
        is($stdout, $output, 'stdout correct') or diag Dumper($stdout);
    };
};

describe "class `$CLASS` is valid" => sub {
    my ($object, $exception, $warnings);

    tests 'valid all properties are teared down' => sub {
        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((
                    file       => 'foo.php',
                    teardown   => 1,
                    properties => { 'foo' => 1 },
                    teared => { 'foo' => 1 },
                ))->isValid();
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is($object, 1, 'file is valid') or diag Dumper($object);
    };

    tests 'valid no properties defined' => sub {
        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((
                    file       => 'foo.php',
                    teardown   => 0,
                ))->isValid();
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is($object, 1, 'file is valid') or diag Dumper($object);
    };
};

done_testing();

