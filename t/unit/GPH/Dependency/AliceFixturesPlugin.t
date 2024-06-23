#!/usr/bin/perl
use strict;
use warnings;

use Test2::V0 -target => 'GPH::Dependency::AliceFixturesPlugin';
use Test2::Tools::Spec;

use GPH::Dependency::Fixture;
use GPH::Dependency::File;
use Data::Dumper;

describe "class `$CLASS` instantiation" => sub {
    tests 'it can be instantiated' => sub {
        can_ok($CLASS, 'new');
    };

    tests 'dies with missing arguments' => sub {
        ok(dies {$CLASS->new()}, 'missing any argument') or note($@);
        ok(dies {$CLASS->new((directories => [ 'Foo', 'Bar' ]))}, 'missing strip and fixtures argument') or note($@);
        ok(dies {$CLASS->new((strip => 'Foo'))}, 'missing directories and fixtures argument') or note($@);
        ok(dies {$CLASS->new((fixture_directories => [ 'Foo' ]))}, 'missing directories and strip argument') or note($@);
        ok(dies {$CLASS->new((fixture_directories => [ 'Foo' ], strip => 'Foo'))}, 'missing directories argument') or note($@);
    };

    tests 'instantiation default values' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((strip => 'Foo', directories => [ 'Foo', 'Bar' ], fixture_directories => [ 'Baz', 'Qux' ]));
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field fixture_directories => array {
                    item 'Baz';
                    item 'Qux';
                    end;
                };
                field directories => array {
                    item 'Foo';
                    item 'Bar';
                    end;
                };
                field excludes => undef;
                field fixture_excludes => undef;
                field strip => 'Foo';
                field type => 1;
                field fixtures => hash {
                    end;
                };
                field classes => hash {
                    end;
                };
                field usages => hash {
                    end;
                };
                field inheritance => hash {
                    end;
                };
                end;
            },
                'object as expected'
        ) or diag Dumper($object);
    };

    tests 'instantiation given values' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((
                    strip               => 'Foo',
                    directories         => [ 'Foo', 'Bar' ],
                    fixture_directories => [ 'Baz', 'Qux' ],
                    excludes            => [ 'Fred', 'Rug' ],
                    fixture_excludes    => [ 'Quack' ],
                    type                => 0
                ));
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field fixture_directories => array {
                    item 'Baz';
                    item 'Qux';
                    end;
                };
                field directories => array {
                    item 'Foo';
                    item 'Bar';
                    end;
                };
                field fixture_excludes => array {
                    item 'Quack';
                    end;
                };
                field excludes => array {
                    item 'Fred';
                    item 'Rug';
                    end;
                };
                field strip => 'Foo';
                field type => 0;
                etc;
            },
                'object as expected'
        ) or diag Dumper($object);
    }
};

describe "class `$CLASS` parse yaml method" => sub {
    my $strip = 't/share/Dependency/';

    tests 'dies with non existing file' => sub {
        ok(dies {$CLASS->new(strip => $strip, directories => [], fixture_directories => [])->parseYaml('foo.yaml')}, 'non existing file') or note($@);
    };

    tests 'parse non yaml' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((
                    strip => $strip, directories => [ 'Foo', 'Bar' ], fixture_directories => [ 't/share/Dependency/Yaml' ])
                );
                $object->parseYaml('foo.txt');
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field fixtures => hash {
                    end;
                };
                etc;
            },
                'object as expected'
        ) or diag Dumper($object);
    };

    tests 'parse yaml' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((
                    strip => $strip, directories => [ 'Foo', 'Bar' ], fixture_directories => [ 't/share/Dependency/Yaml' ])
                );
                $object->parseYaml('t/share/Dependency/Yaml/fixtures.yml');
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field fixtures => hash {
                    field 'Yaml/fixtures.yml' => object {
                        prop blessed => 'GPH::Dependency::Fixture';

                        field file => 'Yaml/fixtures.yml';
                        field dependencies => hash {
                            field 'Foo\MockEntity' => 1;
                            end;
                        };
                        field includes => hash {
                            field 'Yaml/App/fixtures.yaml' => 1;
                            field 'Yaml/App/sub_fixtures.yaml' => 1;
                            field 'Yaml/App/other_fixtures.yaml' => 1;
                            end;
                        };
                        field inheritance => hash {
                            end;
                        };
                        field files => hash {
                            end;
                        };
                    };
                    end;
                };
                etc;
            },
                'object as expected'
        ) or diag Dumper($object);
    };

    tests 'parse yaml with path resolve' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((
                    strip => $strip, directories => [ 'Foo', 'Bar' ], fixture_directories => [ 't/share/Dependency/Yaml' ])
                );
                $object->parseYaml('t/share/Dependency/Yaml/App/sub_fixtures.yaml');
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field fixtures => hash {
                    field 'Yaml/App/sub_fixtures.yaml' => object {
                        prop blessed => 'GPH::Dependency::Fixture';

                        field file => 'Yaml/App/sub_fixtures.yaml';
                        field dependencies => hash {
                            field 'Foo\App\SomeEntity' => 1;
                            field 'Foo\App\AnotherEntity' => 1;
                            end;
                        };
                        field includes => hash {
                            field 'Yaml/fixtures.yaml' => 1;
                            end;
                        };
                        field inheritance => hash {
                            end;
                        };
                        field files => hash {
                            end;
                        };
                    };
                    end;
                };
                etc;
            },
                'object as expected'
        ) or diag Dumper($object);
    };
};

describe "class `$CLASS` parse php method failures" => sub {
    my $strip = 't/share/Dependency/';

    tests 'dies with non existing file' => sub {
        ok(dies {$CLASS->new(strip => $strip, directories => [], fixture_directories => [])->parsePhp('foo.php')}, 'non existing file') or note($@);
    };

    tests 'parse non php' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((
                    strip => $strip, directories => [ 'Foo', 'Bar' ], fixture_directories => [ 't/share/Dependency/Yaml' ])
                );
                $object->parsePhp('foo.txt');
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field classes => hash {
                    end;
                };
                etc;
            },
                'object as expected'
        ) or diag Dumper($object);
    };
};

describe "class `$CLASS` parse php method" => sub {
    my ($type, $resolve);
    my $strip = 't/share/Dependency/';

    case 'with type resolve' => sub {
        $resolve = 1;
        $type = 'class';
    };

    case 'without type resolve' => sub {
        $resolve = 0;
        $type = undef;
    };

    tests 'parse php' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((
                    strip => $strip, directories => [ 'Foo', 'Bar' ], fixture_directories => [ 't/share/Dependency/Yaml' ], type => $resolve)
                );
                $object->parsePhp('t/share/Dependency/Php/RealAbstractNoExtend.php');
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field classes => hash {
                    field 'Php/RealAbstractNoExtend.php' => object {
                        prop blessed => 'GPH::Dependency::File';

                        field file => 'Php/RealAbstractNoExtend.php';
                        field fixtures => hash {
                            field 'Yaml/fixtures.yml' => 1;
                            field 'Yaml/App/sub_fixtures.yaml' => 1;
                            end;
                        };
                        field fqcn => 'Foo\RealAbstractNoExtend';
                        field type => $type;
                        etc;
                    };
                    end;
                };
                etc;
            },
                'object as expected'
        ) or diag Dumper($object);
    };
};

describe "class `$CLASS` php method" => sub {
    my $strip = 't/share/Dependency/';

    tests 'php' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((
                    strip => $strip, directories => [ 't/share/Dependency/Php' ], fixture_directories => [ ])
                )->php();
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field classes => hash {
                    field 'Php/RealAbstractNoExtend.php' => object {
                        prop blessed => 'GPH::Dependency::File';
                    };
                    end;
                };
                etc;
            },
            'object as expected'
        ) or diag Dumper($object);
    };
};

describe "class `$CLASS` inheritance method" => sub {
    my $strip = 't/share/Dependency/';

    tests 'process inheritance' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((
                    strip => $strip, directories => [ 't/share/Dependency/Php' ], fixture_directories => [ 't/share/Dependency/Yaml' ], excludes => [ 't/share/Dependency/Php/App' ])
                )->yaml()->inheritance();
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field fixtures => hash {
                    field 'Yaml/fixtures.yml' => object {
                        prop blessed => 'GPH::Dependency::Fixture';

                        field file => 'Yaml/fixtures.yml';
                        field includes => hash {
                            field 'Yaml/App/fixtures.yaml' => 1;
                            field 'Yaml/App/sub_fixtures.yaml' => 1;
                            field 'Yaml/App/other_fixtures.yaml' => 1;
                            end;
                        };
                        field dependencies => hash {
                            field 'Foo\MockEntity' => 1;
                            end;
                        };
                        field inheritance => hash {
                            field 'Foo\MockEntity' => 1;
                            field 'Foo\App\AnotherEntity' => 1;
                            field 'Foo\App\SomeEntity' => 1;
                            end;
                        };
                        etc;
                    };
                    field 'Yaml/App/sub_fixtures.yaml' => object {
                        prop blessed => 'GPH::Dependency::Fixture';

                        field file => 'Yaml/App/sub_fixtures.yaml';
                        field includes => hash {
                            field 'Yaml/fixtures.yaml' => 1;
                            end;
                        };
                        field dependencies => hash {
                            field 'Foo\App\SomeEntity' => 1;
                            field 'Foo\App\AnotherEntity' => 1;
                            end;
                        };
                        field inheritance => hash {
                            field 'Foo\App\SomeEntity' => 1;
                            field 'Foo\App\AnotherEntity' => 1;
                            end;
                        };
                        etc;
                    };
                    field 'Yaml/App/more_fixtures.yml' => object {
                        prop blessed => 'GPH::Dependency::Fixture';

                        field file => 'Yaml/App/more_fixtures.yml';
                        field includes => hash {
                            end;
                        };
                        field dependencies => hash {
                            field 'App\Foo\FooEntity' => 1;
                            end;
                        };
                        field inheritance => hash {
                            field 'App\Foo\FooEntity' => 1;
                            end;
                        };
                        etc;
                    };
                    field 'Yaml/App/other_fixtures.yaml' => object {
                        prop blessed => 'GPH::Dependency::Fixture';

                        field file => 'Yaml/App/other_fixtures.yaml';
                        field includes => hash {
                            field 'Yaml/App/sub_fixtures.yaml' => 1;
                            end;
                        };
                        field dependencies => hash {
                            field 'Foo\MockEntity' => 1;
                            end;
                        };
                        field inheritance => hash {
                            field 'Foo\App\AnotherEntity' => 1;
                            field 'Foo\App\SomeEntity' => 1;
                            field 'Foo\MockEntity' => 1;
                            end;
                        };
                        etc;
                    };
                    end;
                };
                etc;
            },
                'object as expected'
        ) or diag Dumper($object);
    };
};

describe "class `$CLASS` resolve method" => sub {
    my $strip = 't/share/Dependency/';

    tests 'resolve' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((
                    strip               => $strip,
                    directories         => [],
                    fixture_directories => [],
                    fixtures            => {
                        'Yaml/fixtures.yml' => GPH::Dependency::Fixture->new((
                            file         => 'Yaml/fixtures.yml',
                            dependencies => {
                                'Foo\MockEntity' => 1,
                            },
                            includes     => {
                                'App/fixtures.yaml' => 1,
                            },
                        )),
                    },
                    classes             => {
                        'Php/RealAbstractNoExtend.php' => GPH::Dependency::File->new((
                            file     => 'Php/RealAbstractNoExtend.php',
                            fqcn     => 'Foo\RealAbstractNoExtend',
                            fixtures => {
                                'Yaml/fixtures.yml'              => 1,
                                'Yaml/non_existing_fixtures.yml' => 1,
                            },
                        )),
                    },
                ))->resolve();
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field fixtures => hash {
                    field 'Yaml/fixtures.yml' => object {
                        prop blessed => 'GPH::Dependency::Fixture';

                        field files => hash {
                            field 'Php/RealAbstractNoExtend.php' => 1;
                            end;
                        };
                        etc;
                    };
                    end;
                };
                etc;
            },
                'object as expected'
        ) or diag Dumper($object);
    };
};

describe "class `$CLASS` dependencies method" => sub {
    my $strip = 't/share/Dependency/';

    tests 'process dependencies' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((
                    strip               => $strip,
                    directories         => [],
                    fixture_directories => [],
                    fixtures            => {
                        'Yaml/fixtures.yml' => GPH::Dependency::Fixture->new((
                            file        => 'Yaml/fixtures.yml',
                            inheritance => {
                                'Foo\MockEntity' => 1,
                            },
                            includes    => {
                                'App/fixtures.yaml' => 1,
                            },
                            files       => {
                                'Php/RealAbstractNoExtend.php' => 1,
                            },
                        )),
                    },
                    classes             => {
                        'Php/RealAbstractNoExtend.php' => GPH::Dependency::File->new((
                            file         => 'Php/RealAbstractNoExtend.php',
                            fqcn         => 'Foo\RealAbstractNoExtend',
                            dependencies => {
                                'Foo\Mapper' => 1,
                            },
                        )),
                    },
                ))->dependencies();
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field classes => hash {
                    field 'Php/RealAbstractNoExtend.php' => object {
                        prop blessed => 'GPH::Dependency::File';

                        field dependencies => hash {
                            field 'Foo\Mapper' => 1;
                            field 'Foo\MockEntity' => 1;
                            end;
                        };
                        etc;
                    };
                    end;
                };
                etc;
            },
                'object as expected'
        ) or diag Dumper($object);
    };
};

describe "class `$CLASS` realpath method" => sub {
    my ($path, $expected);
    my $strip = 't/share/Dependency/';

    case 'from cwd' => sub {
        $path = './foo/bar/bax.php';
        $expected = 'foo/bar/bax.php';
    };

    case 'traversal' => sub {
        $path = 'foo/bar/../baz/qux/../bax.php';
        $expected = 'foo/baz/bax.php';
    };

    case 'traversal' => sub {
        $path = "/a/../b/./c//d";
        $expected = 'b/c/d';
    };

    tests 'realpath' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((
                    strip               => $strip,
                    directories         => [],
                    fixture_directories => [],
                ))->dependencies();
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is($expected, $object->realpath($path), 'path as expected') or diag Dumper($object->realpath($path));
    };
};

describe "class `$CLASS` files method" => sub {
    my $strip = 't/share/Dependency/';

    tests 'files' => sub {
        my ($object, $exception, $warnings, $result);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((
                    strip               => $strip,
                    directories         => [ 't/share/Dependency/Php' ],
                    excludes            => [ 't/share/Dependency/Php/App' ],
                    fixture_directories => [ 't/share/Dependency/Yaml' ],
                    fixture_excludes    => [ 't/share/Dependency/Yaml/App' ],
                ));
                $result = $object->files();
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $result,
            hash {
                field 'Php/RealAbstractNoExtend.php' => object {
                    prop blessed => 'GPH::Dependency::File';

                    field 'dependencies' => hash {
                        field 'Foo\MockEntity' => 1;
                        end;
                    };
                    etc;
                };
                etc;
            },
            'object as expected'
        ) or diag Dumper($result);
    };
};

done_testing();

