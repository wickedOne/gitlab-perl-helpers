#!/usr/bin/perl
use strict;
use warnings;

use Test2::V0 -target => 'GPH::Dependency::DependencyMapBuilder';
use Test2::Tools::Spec;

use Data::Dumper;
use GPH::Dependency::File;
use GPH::Dependency::PhpDependencyPlugin;

describe "class `$CLASS` instantiation" => sub {
    tests 'it can be instantiated' => sub {
        can_ok($CLASS, 'new');
    };

    tests 'instantiation default values' => sub {
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
                field plugins => array {
                    end;
                };
                field files => hash {
                    end;
                };
                field dependencies => hash {
                    end;
                };
                field traits => hash {
                    end;
                };
                field inheritance => hash {
                    end;
                };
                field map => hash {
                    end;
                };
                field packages => array {
                    item 'PHPUnit';
                    item 'Symfony';
                    item 'Monolog';
                    item 'PHPStan';
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
                    files    => {
                        'foo.php' => GPH::Dependency::File->new((file => 'foo.php')),
                    },
                    packages => [ 'Foo', 'Bar' ],
                ));
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field plugins => array {
                    end;
                };
                field files => hash {
                    field 'foo.php' => object {
                        prop blessed => 'GPH::Dependency::File';
                        etc;
                    };
                    end;
                };
                field dependencies => hash {
                    end;
                };
                field traits => hash {
                    end;
                };
                field inheritance => hash {
                    end;
                };
                field map => hash {
                    end;
                };
                field packages => array {
                    item 'Foo';
                    item 'Bar';
                    end;
                };
                end;
            },
                'object as expected'
        ) or diag Dumper($object);
    };
};

describe "class `$CLASS` plugins method" => sub {

    tests 'dies with non invalid plugin' => sub {
        ok(dies {$CLASS->new()->plugins([ GPH::Dependency::File->new((file => 'foo.php')) ])}, 'incorrect plugin') or note($@);
    };

    tests 'php dependency plugin' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new()->plugins([ GPH::Dependency::PhpDependencyPlugin->new((strip => 'foo', directories => [])) ]);
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field plugins => array {
                    item 0 => object {
                        prop blessed => 'GPH::Dependency::PhpDependencyPlugin';
                    };
                    end;
                };
                etc;
            },
                'object as expected'
        ) or diag Dumper($object);
    };
};

describe "class `$CLASS` collect method" => sub {

    tests 'dies with non invalid plugin' => sub {
        ok(dies {$CLASS->new()->plugins([ GPH::Dependency::File->new((file => 'foo.php')) ])}, 'incorrect plugin') or note($@);
    };

    tests 'collect with php dependency plugin' => sub {
        my ($object, $exception, $warnings);
        my $strip = 't/share/Dependency/';

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((
                    files => {
                        'Php/App/ExtendFromSameNamespace.php' => GPH::Dependency::File->new((file => 'Php/App/ExtendFromSameNamespace.php')),
                    },
                ))->plugins([
                    GPH::Dependency::PhpDependencyPlugin->new((strip => $strip, directories => [ 't/share/Dependency/Php' ]))
                ])->collect();
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field files => hash {
                    field 'Php/RealAbstractNoExtend.php' => object {
                        prop blessed => 'GPH::Dependency::File';
                    };
                    field 'Php/App/ExtendFromSameNamespace.php' => object {
                        prop blessed => 'GPH::Dependency::File';
                    };
                    field 'Php/App/InterfaceWithExtend.php' => object {
                        prop blessed => 'GPH::Dependency::File';
                    };
                    etc;
                };
                etc;
            },
                'object as expected'
        ) or diag Dumper($object);
    };
};

describe "class `$CLASS` prepare method" => sub {

    tests 'prepare' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((
                    files => {
                        'Php/App/ExtendFromSameNamespace.php' => GPH::Dependency::File->new((
                            file         => 'Php/App/ExtendFromSameNamespace.php',
                            fqcn         => 'Foo\ExtendFromSameNamespace',
                            type         => 'class',
                            dependencies => {
                                'Foo\Mapper'        => 1,
                                'Foo\AnotherMapper' => 1,
                            },
                        )),
                        'Php/Parser/MapperTrait.php'          => GPH::Dependency::File->new((
                            file         => 'Php/Parser/MapperTrait.php',
                            type         => 'trait',
                            fqcn         => 'Foo\MapperTrait',
                            dependencies => {
                                'Foo\Mapper'           => 1,
                                'Foo\YetAnotherMapper' => 1,
                            },
                        )),
                    },
                ))->prepare();
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field dependencies => hash {
                    field 'Foo\Mapper' => hash {
                        field 'Php/App/ExtendFromSameNamespace.php' => 1;
                        field 'Php/Parser/MapperTrait.php' => 1;
                        end;
                    };
                    field 'Foo\AnotherMapper' => hash {
                        field 'Php/App/ExtendFromSameNamespace.php' => 1;
                        end;
                    };
                    field 'Foo\YetAnotherMapper' => hash {
                        field 'Php/Parser/MapperTrait.php' => 1;
                        end;
                    };
                    end;
                };
                field traits => hash {
                    field 'Foo\MapperTrait' => 'Php/Parser/MapperTrait.php';
                    end;
                };
                etc;
            },
                'object as expected'
        ) or diag Dumper($object);
    };
};

describe "class `$CLASS` trait inheritance" => sub {

    tests 'trait' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((
                    files => {
                        'Php/App/ExtendFromSameNamespace.php' => GPH::Dependency::File->new((
                            file         => 'Php/App/ExtendFromSameNamespace.php',
                            fqcn         => 'Foo\ExtendFromSameNamespace',
                            type         => 'class',
                            dependencies => {
                                'Foo\Mapper'        => 1,
                                'Foo\AnotherMapper' => 1,
                                'Foo\MapperTrait'   => 1,
                            },
                        )),
                        'Php/Parser/MapperTrait.php'          => GPH::Dependency::File->new((
                            file         => 'Php/Parser/MapperTrait.php',
                            type         => 'trait',
                            fqcn         => 'Foo\MapperTrait',
                            dependencies => {
                                'Foo\Mapper'           => 1,
                                'Foo\YetAnotherMapper' => 1,
                            },
                        )),
                    },
                ))->prepare()->traits();
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field files => hash {
                    field 'Php/App/ExtendFromSameNamespace.php' => object {
                        prop blessed => 'GPH::Dependency::File';

                        field 'dependencies' => hash {
                            field 'Foo\Mapper' => 1;
                            field 'Foo\AnotherMapper' => 1;
                            field 'Foo\YetAnotherMapper' => 1;
                            field 'Foo\MapperTrait' => 1;
                            end;
                        };
                        etc;
                    };
                    etc;
                };
                etc;
            },
                'object as expected'
        ) or diag Dumper($object);
    };
};

describe "class `$CLASS` inheritance, build and filter method" => sub {
    my %config = (
        files => {
            'Php/App/ExtendFromSameNamespace.php' => GPH::Dependency::File->new((
                file         => 'Php/App/ExtendFromSameNamespace.php',
                fqcn         => 'Foo\ExtendFromSameNamespace',
                type         => 'abstract',
                'extends'    => 'PHPUnit\Framework\TestCase',
                dependencies => {
                    'Foo\Mapper'        => 1,
                    'Foo\AnotherMapper' => 1,
                    'Foo\MapperTrait'   => 1,
                },
            )),
            'Php/App/FooBar.php'                  => GPH::Dependency::File->new((
                file         => 'Php/App/FooBar.php',
                type         => 'class',
                fqcn         => 'Foo\FooBar',
                'extends'    => 'Foo\ExtendFromSameNamespace',
                dependencies => {
                    'Foo\Mapper'           => 1,
                    'Foo\YetAnotherMapper' => 1,
                },
            )),
            'Php/App/FooQux.php'                  => GPH::Dependency::File->new((
                file         => 'Php/App/FooQux.php',
                type         => 'class',
                fqcn         => 'Foo\FooQux',
                dependencies => {
                    'Foo\Mapper'           => 1,
                    'Foo\YetAnotherMapper' => 1,
                },
            )),
            'Php/App/FooFred.php'                  => GPH::Dependency::File->new((
                file         => 'Php/App/FooFred.php',
                type         => 'class',
                fqcn         => 'Foo\FooFred',
                'extends'    => 'Foo\BarCase',
                dependencies => {
                    'Foo\Mapper'           => 1,
                },
            )),
        },
    );

    tests 'inheritance method' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new(%config)->inheritance();
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field inheritance => hash {
                    field 'Foo\FooBar' => object {
                        prop blessed => 'GPH::Dependency::File';

                        field 'inheritance' => hash {
                            field 'Foo\Mapper' => 1;
                            field 'Foo\YetAnotherMapper' => 1;
                            field 'Foo\MapperTrait' => 1;
                            field 'Foo\AnotherMapper' => 1;
                            end;
                        };
                        field valid => 1;
                        etc;
                    };
                    field 'Foo\FooQux' => object {
                        prop blessed => 'GPH::Dependency::File';

                        field 'inheritance' => hash {
                            field 'Foo\Mapper' => 1;
                            field 'Foo\YetAnotherMapper' => 1;
                            end;
                        };
                        field valid => 0;
                        etc;
                    };
                    etc;
                };
                etc;
            },
                'object as expected'
        ) or diag Dumper($object);
    };

    tests 'build method' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new(%config)->build();
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field map => hash {
                    field 'Foo\AnotherMapper' => hash {
                        field 'Php/App/ExtendFromSameNamespace.php' => 1;
                        field 'Php/App/FooBar.php' => 1;
                        end;
                    };
                    field 'Foo\MapperTrait' => hash {
                        field 'Php/App/ExtendFromSameNamespace.php' => 1;
                        field 'Php/App/FooBar.php' => 1;
                        end;
                    };
                    field 'Foo\Mapper' => hash {
                        field 'Php/App/FooBar.php' => 1;
                        field 'Php/App/ExtendFromSameNamespace.php' => 1;
                        end;
                    };
                    field 'Foo\YetAnotherMapper' => hash {
                        field 'Php/App/FooBar.php' => 1;
                        end;
                    };
                    end;
                };
                etc;
            },
                'object as expected'
        ) or diag Dumper($object);
    };

    tests 'filter method' => sub {

        ok(dies {$CLASS->new(%config)->filter()}, 'filter missing any argument') or note($@);

        my ($object, $exception, $warnings, @result);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new(%config)->build();
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        @result = $object->filter((collection => ['Foo\YetAnotherMapper']));

        is(
            \@result,
            array {
                item 'Php/App/FooBar.php';
                end;
            },
            'object as expected'
        ) or diag Dumper(@result);

        @result = $object->filter((collection => ['Foo\AnotherMapper', 'Foo\NonExistingClass']));

        is(
            \@result,
            array {
                item 'Php/App/ExtendFromSameNamespace.php';
                item 'Php/App/FooBar.php';
                end;
            },
            'array contains correct elements'
        ) or diag Dumper(@result);
    };
};

done_testing();

