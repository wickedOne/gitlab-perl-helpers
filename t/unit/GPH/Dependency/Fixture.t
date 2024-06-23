#!/usr/bin/perl

use strict;
use warnings;

use Test2::V0 -target => 'GPH::Dependency::Fixture';
use Test2::Tools::Spec;

use Data::Dumper;

describe "class `$CLASS` instantiation" => sub {
    tests 'it can be instantiated' => sub {
        can_ok($CLASS, 'new');
    };

    tests 'dies with missing file argument' => sub {
        ok(dies {$CLASS->new()}, 'missing file argument') or note($@);
    };

    tests 'instantiation default values' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((file => 'foo.yaml'));
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field file => 'foo.yaml';
                field dependencies => hash {
                    end;
                };
                field inheritance => hash {
                    end;
                };
                field files => hash {
                    end;
                };
                field includes => hash {
                    end;
                };
                end;
            },
            'object as expected'
        ) or diag Dumper($object);
    };

    tests 'instantiation with values' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((
                    file         => 'foo.yaml',
                    dependencies => {
                        'Foo\Bar.php' => 1,
                    },
                    inheritance => {
                        'Foo\Bar.php' => 1,
                    },
                    files => {
                        'file.txt' => 1,
                    },
                    includes => {
                        'include.yaml' => 1,
                    },
                ));
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field file => 'foo.yaml';
                field dependencies => hash {
                    field 'Foo\Bar.php' => 1;
                    end;
                };
                field inheritance => hash {
                    field 'Foo\Bar.php' => 1;
                    end;
                };
                field files => hash {
                    field 'file.txt' => 1;
                    end;
                };
                field includes => hash {
                    field 'include.yaml' => 1;
                    end;
                };
                end;
            },
            'object as expected'
        ) or diag Dumper($object);
    };
};

describe "class `$CLASS` methods" => sub {
    tests 'inheritance method' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS
                    ->new((file => 'foo.yaml', inheritance => {'Foo\Bar.php' => 1}))
                    ->inheritance({'Foo\Bar.php' => 1, 'Baz\Qux.php' => 1});
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field inheritance => hash {
                    field 'Foo\Bar.php' => 1;
                    field 'Baz\Qux.php' => 1;
                    end;
                };
                etc;
            },
            'object as expected'
        ) or diag Dumper($object);
    };
};

done_testing();

