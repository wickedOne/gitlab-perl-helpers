#!/usr/bin/perl
package t::unit::GPH::Util::PhpDependencyParser;

use strict;
use warnings;

use Test2::V0 -target => 'GPH::Util::PhpDependencyParser';
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

        is(
            $object,
            object {
                field usages => {};
                field traits => {};
                field abstracts => {};
                field inheritance => {};
                field classmap => {};
                end;
            },
            'object as expected'
        ) or diag Dumper($object);
    };
};

describe "class `$CLASS` parse method" => sub {
    tests 'dies for non existing directory' => sub {
        ok(dies {$CLASS->new()->parse('foo/bar/baz.php')}, 'died with non existing directory') or note($@);
    };

    tests 'parse non php file' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new();
                $object->parse('t/share/Php/textfile.txt');
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field usages => {};
                field traits => {};
                field abstracts => {};
                field inheritance => {};
                field classmap => {};
                end;
            },
            'object as expected'
        ) or diag Dumper($object);
    };

    tests 'parse php file' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new();
                $object->parse('t/share/Php/Parser/MapperTest.php', 't/share/Php/Parser/');
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field usages => hash {
                    field 'App\Foo\Mapper' => array {
                        item 'MapperTest.php';
                        end;
                    };
                    field 'App\Foo\BarMapper' => array {
                        item 'MapperTest.php';
                        end;
                    };
                };
                field traits => {};
                field abstracts => {};
                field inheritance => hash {
                    field 'App\Tests\Unit\Foo\MapperTest' => hash {
                        field 'extends' => 'App\Tests\Unit\Foo\MapperTestCase';
                        field 'file'    => 'MapperTest.php';
                        field 'usages'  => array {
                            item 'App\Foo\Mapper';
                            item 'App\Foo\BarMapper';
                            end;
                        };
                        end;
                    };
                    end;
                };
                field classmap => hash {
                    field 'MapperTest.php' => 'App\Tests\Unit\Foo\MapperTest';
                    end;
                };
                end;
            }, 'object as expected'
        ) or diag Dumper($object);
    };
};

describe "class `$CLASS` dir method" => sub {
    tests 'dies for missing directories argument' => sub {
        ok(dies {$CLASS->new()->dir((strip => 't/share/Php/Parser/'))}, 'died with missing directories argument') or note($@);
    };

    tests 'dies for missing strip argument' => sub {
        ok(dies {$CLASS->new()->dir((directories => ['t/share/Php/Parser/']))}, 'died with missing directories argument') or note($@);
    };

    tests 'parse directory of php files' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new();
                $object->dir((directories => ['t/share/Php/Parser/'], strip => 't/share/Php/Parser/'));
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field usages => hash {
                    field 'PHPUnit\Framework\TestCase' => array {
                        end;
                    };
                    field 'App\Foo\BarMapper' => array {
                        item 'MapperTest.php';
                        end;
                    };
                    field 'App\Foo\Mapper' => array {
                        item 'MapperTest.php';
                        end;
                    };
                    field 'App\Foo\QuxMapper' => array {
                        end;
                    };
                    field 'App\Tests\Unit\Foo\MapperTrait' => array {
                        item 'Bar/BarMapper.php';
                        end;
                    };
                    field 'App\Foo\BazMapper' => array {
                        end;
                    };
                };
                field traits => hash {
                    field 'App\Tests\Unit\Foo\MapperTrait' => array {
                        item 'App\Foo\BazMapper';
                        end;
                    };
                };
                field abstracts => hash {
                    field 'App\Tests\Unit\Foo\MapperTestCase' => array {
                        item 'App\Foo\QuxMapper';
                        item 'App\Foo\Mapper';
                        item 'App\Tests\Unit\Foo\MapperTrait';
                        item 'PHPUnit\Framework\TestCase';
                        end;
                    };
                };
                field inheritance => hash {
                    field 'App\Tests\Unit\Foo\MapperTest' => hash {
                        field 'extends' => 'App\Tests\Unit\Foo\MapperTestCase';
                        field 'file' => 'MapperTest.php';
                        field 'usages' => array {
                            item 'App\Foo\Mapper';
                            item 'App\Foo\BarMapper';
                            end;
                        };
                        end;
                    };
                    field 'App\Tests\Unit\Foo\MapperTestCase' => hash {
                        field 'extends' => 'PHPUnit\Framework\TestCase';
                        field 'file' => 'MapperTestCase.php';
                        field 'usages' => array {
                            item 'App\Foo\QuxMapper';
                            item 'App\Foo\Mapper';
                            item 'App\Tests\Unit\Foo\MapperTrait';
                            item 'PHPUnit\Framework\TestCase';
                            end;
                        };
                        end;
                    };
                };
                field classmap => hash {
                    field 'MapperTestCase.php' => 'App\Tests\Unit\Foo\MapperTestCase';
                    field 'Bar/BarMapper.php' => 'App\Foo\BarMapper';
                    field 'MapperTrait.php' => 'App\Tests\Unit\Foo\MapperTrait';
                    field 'MapperTest.php' => 'App\Tests\Unit\Foo\MapperTest';
                };
                end;
            },
            'object as expected'
        ) or diag Dumper($object);
    };

    tests 'parse directory of php files and exclude directory' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new();
                $object->dir((directories => ['t/share/Php/Parser/'], excludes => ['t/share/Php/Parser/Bar'], strip => 't/share/Php/Parser/'));
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field usages => hash {
                    field 'PHPUnit\Framework\TestCase' => array {
                        end;
                    };
                    field 'App\Foo\BarMapper' => array {
                        item 'MapperTest.php';
                        end;
                    };
                    field 'App\Foo\Mapper' => array {
                        item 'MapperTest.php';
                        end;
                    };
                    field 'App\Foo\QuxMapper' => array {
                        end;
                    };
                    field 'App\Tests\Unit\Foo\MapperTrait' => array {
                        end;
                    };
                    field 'App\Foo\BazMapper' => array {
                        end;
                    };
                };
                field traits => hash {
                    field 'App\Tests\Unit\Foo\MapperTrait' => array {
                        item 'App\Foo\BazMapper';
                        end;
                    };
                };
                field abstracts => hash {
                    field 'App\Tests\Unit\Foo\MapperTestCase' => array {
                        item 'App\Foo\QuxMapper';
                        item 'App\Foo\Mapper';
                        item 'App\Tests\Unit\Foo\MapperTrait';
                        item 'PHPUnit\Framework\TestCase';
                        end;
                    };
                };
                field inheritance => hash {
                    field 'App\Tests\Unit\Foo\MapperTest' => hash {
                        field 'extends' => 'App\Tests\Unit\Foo\MapperTestCase';
                        field 'file' => 'MapperTest.php';
                        field 'usages' => array {
                            item 'App\Foo\Mapper';
                            item 'App\Foo\BarMapper';
                            end;
                        };
                        end;
                    };
                    field 'App\Tests\Unit\Foo\MapperTestCase' => hash {
                        field 'extends' => 'PHPUnit\Framework\TestCase';
                        field 'file' => 'MapperTestCase.php';
                        field 'usages' => array {
                            item 'App\Foo\QuxMapper';
                            item 'App\Foo\Mapper';
                            item 'App\Tests\Unit\Foo\MapperTrait';
                            item 'PHPUnit\Framework\TestCase';
                            end;
                        };
                        end;
                    };
                };
                field classmap => hash {
                    field 'MapperTestCase.php' => 'App\Tests\Unit\Foo\MapperTestCase';
                    field 'MapperTrait.php' => 'App\Tests\Unit\Foo\MapperTrait';
                    field 'MapperTest.php' => 'App\Tests\Unit\Foo\MapperTest';
                };
                end;
            },
                'object as expected'
        ) or diag Dumper($object);
    };
};

describe "class `$CLASS` inheritance method" => sub {
    tests 'parse directory of php files and apply inheritance' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new();
                $object->dir((directories => ['t/share/Php/Parser/'], strip => 't/share/Php/Parser/'))->inheritance();
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field usages => hash {
                    field 'PHPUnit\Framework\TestCase' => array {
                        item 'MapperTest.php';
                        end;
                    };
                    field 'App\Foo\BarMapper' => array {
                        item 'MapperTest.php';
                        end;
                    };
                    field 'App\Foo\Mapper' => array {
                        item 'MapperTest.php';
                        item 'MapperTest.php';
                        end;
                    };
                    field 'App\Foo\QuxMapper' => array {
                        item 'MapperTest.php';
                        end;
                    };
                    field 'App\Tests\Unit\Foo\MapperTrait' => array {
                        item 'Bar/BarMapper.php';
                        item 'MapperTest.php';
                        end;
                    };
                    field 'App\Foo\BazMapper' => array {
                        end;
                    };
                    end;
                };
                field traits => hash {
                    field 'App\Tests\Unit\Foo\MapperTrait' => array {
                        item 'App\Foo\BazMapper';
                        end;
                    };
                    end;
                };
                field abstracts => hash {
                    field 'App\Tests\Unit\Foo\MapperTestCase' => array {
                        item 'App\Foo\QuxMapper';
                        item 'App\Foo\Mapper';
                        item 'App\Tests\Unit\Foo\MapperTrait';
                        item 'PHPUnit\Framework\TestCase';
                        end;
                    };
                    end;
                };
                field inheritance => hash {
                    field 'App\Tests\Unit\Foo\MapperTest' => hash {
                        field 'extends' => 'App\Tests\Unit\Foo\MapperTestCase';
                        field 'file' => 'MapperTest.php';
                        field 'usages' => array {
                            item 'App\Foo\Mapper';
                            item 'App\Foo\BarMapper';
                            end;
                        };
                        end;
                    };
                    field 'App\Tests\Unit\Foo\MapperTestCase' => hash {
                        field 'extends' => 'PHPUnit\Framework\TestCase';
                        field 'file' => 'MapperTestCase.php';
                        field 'usages' => array {
                            item 'App\Foo\QuxMapper';
                            item 'App\Foo\Mapper';
                            item 'App\Tests\Unit\Foo\MapperTrait';
                            item 'PHPUnit\Framework\TestCase';
                            end;
                        };
                        end;
                    };
                    end;
                };
                field classmap => hash {
                    field 'MapperTestCase.php' => 'App\Tests\Unit\Foo\MapperTestCase';
                    field 'Bar/BarMapper.php' => 'App\Foo\BarMapper';
                    field 'MapperTrait.php' => 'App\Tests\Unit\Foo\MapperTrait';
                    field 'MapperTest.php' => 'App\Tests\Unit\Foo\MapperTest';
                    end;
                };
                end;
            },
            'object as expected'
        ) or diag Dumper($object);
    };
};

describe "class `$CLASS` traits method" => sub {
    tests 'parse directory of php files and apply traits' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new();
                $object->dir((directories => ['t/share/Php/Parser/'], strip => 't/share/Php/Parser/'))
                    ->traits()
                ;
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field usages => hash {
                    field 'PHPUnit\Framework\TestCase' => array {
                        end;
                    };
                    field 'App\Foo\BarMapper' => array {
                        item 'MapperTest.php';
                        end;
                    };
                    field 'App\Foo\Mapper' => array {
                        item 'MapperTest.php';
                        end;
                    };
                    field 'App\Foo\QuxMapper' => array {
                        end;
                    };
                    field 'App\Tests\Unit\Foo\MapperTrait' => array {
                        item 'Bar/BarMapper.php';
                        end;
                    };
                    field 'App\Foo\BazMapper' => array {
                        item 'Bar/BarMapper.php';
                        end;
                    };
                    end;
                };
                field traits => hash {
                    field 'App\Tests\Unit\Foo\MapperTrait' => array {
                        item 'App\Foo\BazMapper';
                        end;
                    };
                    end;
                };
                field abstracts => hash {
                    field 'App\Tests\Unit\Foo\MapperTestCase' => array {
                        item 'App\Foo\QuxMapper';
                        item 'App\Foo\Mapper';
                        item 'App\Tests\Unit\Foo\MapperTrait';
                        item 'PHPUnit\Framework\TestCase';
                        end;
                    };
                    end;
                };
                field inheritance => hash {
                    field 'App\Tests\Unit\Foo\MapperTest' => hash {
                        field 'extends' => 'App\Tests\Unit\Foo\MapperTestCase';
                        field 'file' => 'MapperTest.php';
                        field 'usages' => array {
                            item 'App\Foo\Mapper';
                            item 'App\Foo\BarMapper';
                            end;
                        };
                    };
                    field 'App\Tests\Unit\Foo\MapperTestCase' => hash {
                        field 'extends' => 'PHPUnit\Framework\TestCase';
                        field 'file' => 'MapperTestCase.php';
                        field 'usages' => array {
                            item 'App\Foo\QuxMapper';
                            item 'App\Foo\Mapper';
                            item 'App\Tests\Unit\Foo\MapperTrait';
                            item 'PHPUnit\Framework\TestCase';
                            end;
                        };
                        end;
                    };
                    end;
                };
                field classmap => hash {
                    field 'MapperTestCase.php' => 'App\Tests\Unit\Foo\MapperTestCase';
                    field 'Bar/BarMapper.php' => 'App\Foo\BarMapper';
                    field 'MapperTrait.php' => 'App\Tests\Unit\Foo\MapperTrait';
                    field 'MapperTest.php' => 'App\Tests\Unit\Foo\MapperTest';
                };
                end;
            },
            'object as expected'
        ) or diag Dumper($object);
    };
};

describe "class `$CLASS` sanitise method" => sub {
    tests 'parse directory of php files and sanitise' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new();
                $object->dir((directories => ['t/share/Php/Parser/'], strip => 't/share/Php/Parser/'))
                    ->sanitise()
                ;
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field usages => hash {
                    field 'PHPUnit\Framework\TestCase' => array {
                        end;
                    };
                    field 'App\Foo\BarMapper' => array {
                        item 'MapperTest.php';
                        end;
                    };
                    field 'App\Foo\Mapper' => array {
                        item 'MapperTest.php';
                        end;
                    };
                    field 'App\Foo\QuxMapper' => array {
                        end;
                    };
                    field 'App\Foo\BazMapper' => array {
                        end;
                    };
                    end;
                };
                field traits => hash {
                    field 'App\Tests\Unit\Foo\MapperTrait' => array {
                        item 'App\Foo\BazMapper';
                        end;
                    };
                    end;
                };
                field abstracts => hash {
                    field 'App\Tests\Unit\Foo\MapperTestCase' => array {
                        item 'App\Foo\QuxMapper';
                        item 'App\Foo\Mapper';
                        item 'App\Tests\Unit\Foo\MapperTrait';
                        item 'PHPUnit\Framework\TestCase';
                    };
                    end;
                };
                field inheritance => hash {
                    field 'App\Tests\Unit\Foo\MapperTest' => hash {
                        field 'extends' => 'App\Tests\Unit\Foo\MapperTestCase';
                        field 'file' => 'MapperTest.php';
                        field 'usages' => array {
                            item 'App\Foo\Mapper';
                            item 'App\Foo\BarMapper';
                            end;
                        };
                    };
                    field 'App\Tests\Unit\Foo\MapperTestCase' => hash {
                        field 'extends' => 'PHPUnit\Framework\TestCase';
                        field 'file' => 'MapperTestCase.php';
                        field 'usages' => array {
                            item 'App\Foo\QuxMapper';
                            item 'App\Foo\Mapper';
                            item 'App\Tests\Unit\Foo\MapperTrait';
                            item 'PHPUnit\Framework\TestCase';
                            end;
                        };
                    };
                    end;
                };
                field classmap => hash {
                    field 'MapperTestCase.php' => 'App\Tests\Unit\Foo\MapperTestCase';
                    field 'Bar/BarMapper.php' => 'App\Foo\BarMapper';
                    field 'MapperTrait.php' => 'App\Tests\Unit\Foo\MapperTrait';
                    field 'MapperTest.php' => 'App\Tests\Unit\Foo\MapperTest';
                    end;
                };
                end;
            },
            'object as expected'
        ) or diag Dumper($object);
    };
};

describe "class `$CLASS` filter method" => sub {
    my @filter = qw(App\Foo\BazMapper App\Foo\QuxMapper App\Foo\NonExisting);

    tests 'dies for missing argument' => sub {
        ok(dies {$CLASS->new()->dir((directories => ['t/share/Php/Parser/'], strip => 't/share/Php/Parser/'))->filter((collection => \@filter, out => 'namespaces'))}, 'died with missing "in" argument') or note($@);
        ok(dies {$CLASS->new()->dir((directories => ['t/share/Php/Parser/'], strip => 't/share/Php/Parser/'))->filter((collection => \@filter, in => 'namespaces'))}, 'died with missing "out" argument') or note($@);
        ok(dies {$CLASS->new()->dir((directories => ['t/share/Php/Parser/'], strip => 't/share/Php/Parser/'))->filter((in => 'namespaces', out => 'files'))}, 'died with missing "collection" argument') or note($@);
    };

    tests 'filter parsed dependency map' => sub {
        my ($object, @result, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new();
                @result = $object->dir((directories => ['t/share/Php/Parser/'], strip => 't/share/Php/Parser/'))
                    ->inheritance()
                    ->traits()
                    ->sanitise()
                    ->filter((collection => \@filter, in => 'namespaces', out => 'files'))
                ;
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            \@result,
            array {
                item 'Bar/BarMapper.php';
                item 'MapperTest.php';
            },
            'object as expected'
        ) or diag Dumper(@result);
    };

    tests 'classnames from filtered dependency map' => sub {
        my ($object, @result, $exception, $warnings);
        my @files = qw(Bar/BarMapper.php MapperNonExisting.php);
        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new();
                @result = $object->dir((directories => ['t/share/Php/Parser/'], strip => 't/share/Php/Parser/'))
                    ->inheritance()
                    ->traits()
                    ->sanitise()
                    ->filter((collection => \@files, in => 'files', out => 'namespaces'))
                ;
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            \@result,
            array {
                item 'App\Tests\Unit\Foo\MapperTest';
                end;
            },
            'object as expected'
        ) or diag Dumper(@result);
    };
};

done_testing();
