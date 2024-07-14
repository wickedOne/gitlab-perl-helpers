#!/usr/bin/perl
package t::unit::GPH::PHPUnit::Teardown;

use strict;
use warnings;

use Test2::V0 -target => 'GPH::PHPUnit::Teardown';
use Test2::Tools::Spec;

use Data::Dumper;

describe "class `$CLASS` instantiation" => sub {
    tests 'it can be instantiated' => sub {
        can_ok($CLASS, 'new');
    };

    tests "mandatory config options" => sub {
        ok(dies {$CLASS->new()}, 'died with missing files option') or note($@);
    };

    tests 'instantiation with default values' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((files => ['foo.php']));
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field files => array {
                    item 'foo.php';
                    end;
                };
                field debug => 0;
                field strict => 0;
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
                $object = $CLASS->new((files => ['foo.php'], debug => 1, strict => 1));
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field files => array {
                    item 'foo.php';
                    end;
                };
                field debug => 1;
                field strict => 1;
                field teared => hash {
                    end;
                };
                end;
            },
            'object as expected',
            Dumper($object)
        );
    };
};

describe "class `$CLASS` parse method" => sub {
    my $file = 't/share/PHPUnit/TeardownTest.php';

    tests "parse non existing file" => sub {
        ok(dies {$CLASS->new(files => ['fooTest.php'])->parse()}, 'died with non existing file') or note($@);
    };

    tests 'parse text file' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((files => ['t/share/PHPUnit/phpunit-baseline.txt']))->parse();
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field files => array {
                    item 't/share/PHPUnit/phpunit-baseline.txt';
                    end;
                };
                field debug => 0;
                field strict => 0;
                field teared => hash {
                    end;
                };
                end;
            },
            'object as expected',
            Dumper($object)
        );
    };

    tests 'parse test class' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((files => [$file]))->parse();
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field files => array {
                    item $file;
                    end;
                };
                field debug => 0;
                field strict => 0;
                field teared => hash {
                    field $file => object {
                        prop blessed => 'GPH::PHPUnit::Teared';

                        field file => $file;
                        field teardown => 1;
                        field properties => hash {
                            field 'foo' => '?int';
                            field 'fixtures' => 'array';
                            field 'config' => 'Configuration';
                            field 'fooProvider' => '?FooProvider';
                            field 'barProvider' => 'BarProvider';
                            field 'entityManager' => '?EntityManagerInterface';
                            end;
                        };
                        field teared => hash {
                            field 'foo' => 1;
                            field 'fixtures' => 1;
                            field 'fooProvider' => 1;
                            end;
                        };
                    };
                    end;
                };
                end;
            },
            'object as expected',
            Dumper($object)
        );
    };

    tests 'parse test class with debug' => sub {
        my ($object, $exception, $warnings, $stdout);

        my $expected = "processing file: t/share/PHPUnit/TeardownTest.php
  property: foo type: ?int
  property: fixtures type: array
  property: config type: Configuration
  property: fooProvider type: ?FooProvider
  property: barProvider type: BarProvider
  property: entityManager type: ?EntityManagerInterface
  has teardown
  property: foo was found in teardown
  property: fixtures was found in teardown
  has teardown
  property: fooProvider was found in teardown";

        $exception = dies {
            $warnings = warns {
                local *STDOUT;

                open *STDOUT, '>', \$stdout;

                $object = $CLASS->new((files => [$file], debug => 1))->parse();

                close *STDOUT;
                chomp $stdout;
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is($stdout, $expected, 'stdout as expected') or diag Dumper($stdout);
    };

    tests 'parse test class in strict mode' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((files => [$file], strict => 1))->parse();
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field files => array {
                    item $file;
                    end;
                };
                field debug => 0;
                field strict => 1;
                field teared => hash {
                    field $file => object {
                        prop blessed => 'GPH::PHPUnit::Teared';

                        field file => $file;
                        field teardown => 1;
                        field properties => hash {
                            field 'fixtures' => 'array';
                            field 'history' => 'array';
                            field 'config' => 'Configuration';
                            field 'foo' => '?int';
                            field 'barProvider' => 'BarProvider';
                            field 'bar' => 'string';
                            field 'fooProvider' => '?FooProvider';
                            field 'entityManager' => '?EntityManagerInterface';
                            end;
                        };
                        field teared => hash {
                            field 'foo' => 1;
                            field 'fixtures' => 1;
                            field 'fooProvider' => 1;
                            end;
                        };
                    };
                    end;
                };
                end;
            },
            'object as expected',
            Dumper($object)
        );
    };
};
describe "class `$CLASS` validate method" => sub {
    tests 'validate' => sub {
        my ($result, $object, $stdout, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                local *STDOUT;

                open *STDOUT, '>', \$stdout;

                $object = $CLASS
                    ->new((files => ['t/share/PHPUnit/ValidTeardownTestCase.php', 't/share/PHPUnit/TeardownTest.php', 't/share/PHPUnit/InvalidTeardownTestCase.php']))
                    ->parse();

                $result = $object->validate();

                close *STDOUT;
                chomp $stdout;
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is($result, 1, 'teardown check has invalid files') or diag Dumper($object);
        is($stdout, 'file t/share/PHPUnit/InvalidTeardownTestCase.php is invalid: property \'bar\' is not teared down
file t/share/PHPUnit/TeardownTest.php is invalid: properties \'barProvider\', \'config\', \'entityManager\' are not teared down', 'stdout as expected') or diag Dumper($stdout);
    };
};

done_testing();

