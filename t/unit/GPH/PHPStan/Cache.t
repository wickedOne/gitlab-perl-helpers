#!/usr/bin/perl
package t::unit::GPH::PHPStan::Cache;

use strict;
use warnings;

use Test2::V0 -target => 'GPH::PHPStan::Cache';
use Test2::Tools::Spec;

use Data::Dumper;

describe "class `$CLASS`" => sub {
    tests 'it can be instantiated' => sub {
        can_ok($CLASS, 'new');
    };

    tests 'instantiation without arguments' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new();
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is (
            $object,
            object {
                field depth => 1;
                field relative => undef;
                field dependencies => undef;
            },
            'object as expected'
        ) or diag Dumper($object);
    };

    tests 'instantiation with arguments' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((depth => 2, relative => 'build/'));
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is (
            $object,
            object {
                field depth => 2;
                field relative => 'build/';
                field dependencies => undef;
            },
                'object as expected'
        ) or diag Dumper($object);
    };
};

describe "class `$CLASS` parseResultCache method" => sub {
    tests 'dies for missing path argument' => sub {
        ok(dies {$CLASS->new()->parseResultCache()}, 'missing path argument') or note($@);
    };

    tests 'dies for incorrect path argument' => sub {
        ok(dies {$CLASS->new()->parseResultCache((path => 'foo/bar/baz.php'))}, 'missing path argument') or note($@);
    };

    tests 'test parseResultCache without constructor arguments' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new()->parseResultCache((path => 't/share/PHPStan/resultCache.php'));
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is (
            $object,
            object {
                field depth => 1;
                field relative => undef;
                field dependencies => hash {
                    field '/builds/phrase-tag-bundle/src/Foo/Baz.php' => array {
                        item '/builds/phrase-tag-bundle/src/Foo/Qux.php';
                        item '/builds/phrase-tag-bundle/src/Foo/Corge.php';
                        end;
                    };
                    field '/builds/phrase-tag-bundle/src/Foo/Bar.php' => array {
                        item '/builds/phrase-tag-bundle/src/Foo/Baz.php';
                        end;
                    };
                };
            },
            'object as expected'
        ) or diag Dumper($object);
    };

    tests 'test parseResultCache with constructor arguments' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((depth => 2, relative => 'src/'))
                    ->parseResultCache((path => 't/share/PHPStan/resultCache.php'));
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is (
            $object,
            object {
                field depth => 2;
                field relative => 'src/';
                field dependencies => hash {
                    field 'src/Foo/Baz.php' => array {
                        item 'src/Foo/Qux.php';
                        item 'src/Foo/Corge.php';
                        end;
                    };
                    field 'src/Foo/Bar.php' => array {
                        item 'src/Foo/Baz.php';
                        end;
                    };
                };
            },
            'object as expected'
        ) or diag Dumper($object);
    };
};

describe "class `$CLASS` dependencies method" => sub {
    tests 'test without constructor arguments' => sub {
        my (@result, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                @result = $CLASS->new()
                    ->parseResultCache((path => 't/share/PHPStan/resultCache.php'))
                    ->dependencies(qw(/builds/phrase-tag-bundle/src/Foo/Bar.php))
                    ;
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is (
            \@result,
            array {
                item '/builds/phrase-tag-bundle/src/Foo/Bar.php';
                item '/builds/phrase-tag-bundle/src/Foo/Baz.php';
                end;
            }, 'result as expected'
        ) or diag Dumper(@result);
    };

    tests 'test with constructor arguments' => sub {
        my (@result, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                @result = $CLASS->new((depth => 2, relative => 'src/'))
                    ->parseResultCache((path => 't/share/PHPStan/resultCache.php'))
                    ->dependencies(qw(src/Foo/Bar.php))
                ;
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is (
            \@result,
            array {
                item 'src/Foo/Bar.php';
                item 'src/Foo/Baz.php';
                item 'src/Foo/Qux.php';
                item 'src/Foo/Corge.php';
                end;
            }, 'result as expected'
        ) or diag Dumper(@result);
    };
};

done_testing();

