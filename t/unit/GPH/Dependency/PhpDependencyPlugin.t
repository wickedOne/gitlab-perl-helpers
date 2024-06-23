#!/usr/bin/perl

use strict;
use warnings;

use Test2::V0 -target => 'GPH::Dependency::PhpDependencyPlugin';
use Test2::Tools::Spec;

use GPH::Dependency::Fixture;
use Data::Dumper;

describe "class `$CLASS` instantiation" => sub {
    tests 'it can be instantiated' => sub {
        can_ok($CLASS, 'new');
    };

    tests 'dies with missing arguments' => sub {
        ok(dies {$CLASS->new()}, 'missing any argument') or note($@);
        ok(dies {$CLASS->new((directories => ['Foo', 'Bar']))}, 'missing strip argument') or note($@);
        ok(dies {$CLASS->new((strip => 'Foo'))}, 'missing directories argument') or note($@);
    };

    tests 'instantiation default values' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((strip => 'Foo', directories => ['Foo', 'Bar']));
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field directories => array {
                    item 'Foo';
                    item 'Bar';
                    end;
                };
                field excludes => undef;
                field strip => 'Foo';
                field files => hash {
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
                $object = $CLASS->new((strip => 'Foo', directories => ['Foo', 'Bar'], excludes => ['Baz', 'Qux']));
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field directories => array {
                    item 'Foo';
                    item 'Bar';
                    end;
                };
                field excludes => array {
                    item 'Baz';
                    item 'Qux';
                    end;
                };;
                field strip => 'Foo';
                field files => hash {
                    end;
                };
                end;
            },
                'object as expected'
        ) or diag Dumper($object);
    };
};

describe "class `$CLASS` parse method" => sub {
    my $strip = 't/share/Dependency/';

    tests 'dies with non existing file' => sub {
        ok(dies {$CLASS->new((strip => $strip, directories => ['Foo', 'Bar']))->parse('foo.php')}, 'non existing file') or note($@);
    };

    tests 'parse with non php file' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((strip => $strip, directories => ['Foo', 'Bar']))->parse('foo.txt');
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field directories => array {
                    item 'Foo';
                    item 'Bar';
                    end;
                };
                field excludes => undef;
                field strip => $strip;
                field files => hash {
                    end;
                };
                end;
            },
            'object as expected'
        ) or diag Dumper($object);
    };

    tests 'parse with abstract php file extending aliased class' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((strip => $strip, directories => ['Foo', 'Bar']))->parse('t/share/Dependency/Php/App/AbstractWithAliasTestCase.php');
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field files => hash {
                    field 'Php/App/AbstractWithAliasTestCase.php' => object {
                        prop blessed => 'GPH::Dependency::File';

                        field 'type' => 'abstract';
                        field 'extends' => 'PHPUnit\Framework\TestCase';
                        field 'fqcn' => 'Foo\App\AbstractWithAliasTestCase';
                        field 'dependencies' => hash {
                            field 'Foo\Mapper' => 1;
                            field 'PHPUnit\Framework\TestCase' => 1;
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

    tests 'parse with interface php file extending class' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((strip => $strip, directories => ['Foo', 'Bar']))->parse('t/share/Dependency/Php/App/InterfaceWithExtend.php');
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field files => hash {
                    field 'Php/App/InterfaceWithExtend.php' => object {
                        prop blessed => 'GPH::Dependency::File';

                        field 'type' => 'interface';
                        field 'extends' => 'PHPUnit\Framework\TestCase';
                        field 'fqcn' => 'Foo\App\InterfaceWithExtend';
                        field 'dependencies' => hash {
                            field 'Foo\Mapper' => 1;
                            field 'PHPUnit\Framework\TestCase' => 1;
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

    tests 'parse class extending class from same namespace' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((strip => $strip, directories => ['Foo', 'Bar']))->parse('t/share/Dependency/Php/App/ExtendFromSameNamespace.php');
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

                        field 'type' => 'class';
                        field 'extends' => 'Foo\App\TestCase';
                        field 'fqcn' => 'Foo\App\ExtendFromSameNamespace';
                        field 'dependencies' => hash {
                            field 'Foo\Mapper' => 1;
                            field 'Foo\App\TestCase' => 1;
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

    tests 'parse abstract class no extend' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((strip => $strip, directories => ['Foo', 'Bar']))->parse('t/share/Dependency/Php/RealAbstractNoExtend.php');
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

                        field 'type' => 'abstract';
                        field 'extends' => undef;
                        field 'fqcn' => 'Foo\RealAbstractNoExtend';
                        field 'dependencies' => hash {
                            field 'Foo\Mapper' => 1;
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

describe "class `$CLASS` dir and files method" => sub {
    my $strip = 't/share/Dependency/';

    tests 'dir method' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((strip => $strip, directories => ['t/share/Dependency/Php'], excludes => ['t/share/Dependency/Php/App']))->dir();
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

                        field 'type' => 'abstract';
                        field 'extends' => undef;
                        field 'fqcn' => 'Foo\RealAbstractNoExtend';
                        field 'dependencies' => hash {
                            field 'Foo\Mapper' => 1;
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

    tests 'files method' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((strip => $strip, directories => ['t/share/Dependency/Php']))->files();
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            hash {
                field 'Php/RealAbstractNoExtend.php' => object {
                    prop blessed => 'GPH::Dependency::File';

                    field 'type' => 'abstract';
                    field 'extends' => undef;
                    field 'fqcn' => 'Foo\RealAbstractNoExtend';
                    field 'dependencies' => hash {
                        field 'Foo\Mapper' => 1;
                        end;
                    };
                    etc;
                };
                etc;
            },
                'object as expected'
        ) or diag Dumper($object);
    };

    tests 'instantiation given values' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((strip => 'Foo', directories => ['Foo', 'Bar'], excludes => ['Baz', 'Qux']));
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field directories => array {
                    item 'Foo';
                    item 'Bar';
                    end;
                };
                field excludes => array {
                    item 'Baz';
                    item 'Qux';
                    end;
                };;
                field strip => 'Foo';
                field files => hash {
                    end;
                };
                end;
            },
                'object as expected'
        ) or diag Dumper($object);
    };
};

done_testing();

