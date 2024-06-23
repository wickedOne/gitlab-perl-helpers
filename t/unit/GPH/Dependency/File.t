#!/usr/bin/perl
use strict;
use warnings;

use Test2::V0 -target => 'GPH::Dependency::File';
use Test2::Tools::Spec;

use GPH::Dependency::Fixture;
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
                $object = $CLASS->new((file => 'foo.php'));
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field file => 'foo.php';
                field fqcn => undef;
                field dependencies => hash {
                    end;
                };
                field extends => undef;
                field type => undef;
                field fixtures => hash {
                    end;
                };
                field inheritance => hash {
                    end;
                };
                field valid => 0;
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
                    file         => 'foo.php',
                    fqcn         => 'Foo\Bar',
                    dependencies => {
                        'Foo\Bar.php' => 1,
                    },
                    extends      => 'Foo\Qux',
                    type         => 'class',
                    fixtures     => {
                        'include.yaml' => 1,
                    },
                    inheritance  => {
                        'Foo\Bar.php' => 1,
                    },
                    valid        => 1,
                ));
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field file => 'foo.php';
                field fqcn => 'Foo\Bar';
                field dependencies => hash {
                    field 'Foo\Bar.php' => 1;
                    end;
                };
                field extends => 'Foo\Qux';
                field type => 'class';
                field fixtures => hash {
                    field 'include.yaml' => 1;
                    end;
                };
                field inheritance => hash {
                    field 'Foo\Bar.php' => 1;
                    end;
                };
                field valid => 1;
                end;
            },
            'object as expected'
        ) or diag Dumper($object);
    };
};

describe "class `$CLASS` merge method" => sub {
    tests 'dies with incorrect file argument' => sub {
        ok(dies {$CLASS->new((file => 'file.php'))->merge(GPH::Dependency::Fixture->new((file => 'file.yaml')))}, 'incorrect file object') or note($@);
        ok(dies {$CLASS->new((file => 'file.php'))->merge(GPH::Dependency::File->new((file => 'file.yaml')))}, 'incorrect file path') or note($@);
    };

    tests 'merge method no default values' => sub {
        my ($object, $child, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((file => 'file.php'));
                $child = $CLASS->new((file => 'file.php'));
                $object->merge($child);
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field file => 'file.php';
                field fqcn => undef;
                field dependencies => hash {
                    end;
                };
                field extends => undef;
                field type => undef;
                field fixtures => hash {
                    end;
                };
                field inheritance => hash {
                    end;
                };
                field valid => 0;
                end;
            },
            'object as expected'
        ) or diag Dumper($object);
    };

    tests 'merge method no default values, default values child' => sub {
        my ($object, $child, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((file => 'file.php'));
                $child = $CLASS->new((
                    file         => 'file.php',
                    fqcn         => 'Foo\Bar',
                    dependencies => {
                        'Foo\Bar.php' => 1,
                    },
                    extends      => 'Foo\Qux',
                    type         => 'class',
                    fixtures     => {
                        'include.yaml' => 1,
                    },
                    inheritance  => {
                        'Foo\Bar.php' => 1,
                    },
                    valid        => 1,
                ));
                $object->merge($child);
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field file => 'file.php';
                field fqcn => 'Foo\Bar';
                field dependencies => hash {
                    field 'Foo\Bar.php' => 1;
                    end;
                };
                field extends => 'Foo\Qux';
                field type => 'class';
                field fixtures => hash {
                    field 'include.yaml' => 1;
                    end;
                };
                field inheritance => hash {
                    field 'Foo\Bar.php' => 1;
                    end;
                };
                field valid => 0;
                end;
            },
            'object as expected'
        ) or diag Dumper($object);
    };

    tests 'merge method with default values' => sub {
        my ($object, $child, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((
                    file         => 'file.php',
                    fqcn         => 'Foo\Qux',
                    dependencies => {
                        'Foo\Baz.php' => 1,
                    },
                    extends      => 'TestCase',
                    type         => 'trait',
                    fixtures     => {
                        'include-fixture.yaml' => 1,
                    },
                    inheritance  => {
                        'Foo\Baz.php' => 1,
                    },
                    valid        => 1,
                ));
                $child = $CLASS->new((
                    file         => 'file.php',
                    fqcn         => 'Foo\Bar',
                    dependencies => {
                        'Foo\Bar.php' => 1,
                    },
                    extends      => 'Foo\Qux',
                    type         => 'class',
                    fixtures     => {
                        'include.yaml' => 1,
                    },
                    inheritance  => {
                        'Foo\Bar.php' => 1,
                    },
                    valid        => 0,
                ));
                $object->merge($child);
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field file => 'file.php';
                field fqcn => 'Foo\Qux';
                field dependencies => hash {
                    field 'Foo\Bar.php' => 1;
                    field 'Foo\Baz.php' => 1;
                    end;
                };
                field extends => 'TestCase';
                field type => 'trait';
                field fixtures => hash {
                    field 'include.yaml' => 1;
                    field 'include-fixture.yaml' => 1;
                    end;
                };
                field inheritance => hash {
                    field 'Foo\Bar.php' => 1;
                    field 'Foo\Baz.php' => 1;
                    end;
                };
                field valid => 1;
                end;
            },
            'object as expected'
        ) or diag Dumper($object);
    };
};

describe "class `$CLASS` dependencies method" => sub {
    tests 'dies with incorrect file argument' => sub {
        ok(dies {$CLASS->new((file => 'file.php'))->dependencies(GPH::Dependency::Fixture->new((file => 'file.yaml')))}, 'incorrect file object') or note($@);
    };

    tests 'dependencies method' => sub {
        my ($object, $child, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((file => 'foo.php', dependencies => {'Foo\Bar.php' => 1, 'Bar\Qux.php' => 1}));
                $child = $CLASS->new((file => 'bar.php', dependencies => {'Foo\Bar.php' => 1, 'Foo\Baz.php' => 1}));
                $object->dependencies($child);
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field dependencies => hash {
                    field 'Foo\Bar.php' => 1;
                    field 'Bar\Qux.php' => 1;
                    field 'Foo\Baz.php' => 1;
                    end;
                };
                etc;
            },
            'object as expected'
        ) or diag Dumper($object);
    };
};

describe "class `$CLASS` inheritance method" => sub {
    tests 'dies with incorrect file argument' => sub {
        ok(dies {$CLASS->new((file => 'file.php'))->inheritance(GPH::Dependency::Fixture->new((file => 'file.yaml')))}, 'incorrect file object') or note($@);
    };

    tests 'dependencies method' => sub {
        my ($object, $child, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((file => 'foo.php', inheritance => {'Foo\Bar.php' => 1, 'Bar\Qux.php' => 1}));
                $child = $CLASS->new((file => 'bar.php', dependencies => {'Foo\Bar.php' => 1, 'Foo\Baz.php' => 1}));
                $object->inheritance($child);
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field inheritance => hash {
                    field 'Foo\Bar.php' => 1;
                    field 'Bar\Qux.php' => 1;
                    field 'Foo\Baz.php' => 1;
                    end;
                };
                etc;
            },
            'object as expected'
        ) or diag Dumper($object);
    };
};

done_testing();

