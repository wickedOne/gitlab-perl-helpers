#!/usr/bin/perl
package t::unit::GPH::Util::Php;

use strict;
use warnings;

use Test2::V0 -target => 'GPH::Util::Php';
use Test2::Tools::Spec;

use Data::Dumper;

my @paths = qw{t/share/Php/Foo.php t/share/Php/FooEnum.php t/share/Php/MethodEnum.php t/share/Php/SomethingInterface.php t/share/Php/SomethingTrait.php t/share/Php/textfile.txt t/share/Php/Bar.php};

describe "class `$CLASS`" => sub {
    tests 'it can be instantiated' => sub {
        can_ok($CLASS, 'new');
    };

    tests 'instantation' => sub {
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
                field types => {};
                end;
            },
            'object as expected'
        ) or diag Dumper($object);
    };
};

describe "class `$CLASS` types method" => sub {
    tests 'types' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new();
                $object->types(@paths);
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field types => hash {
                    field interface => array {
                        item 't/share/Php/SomethingInterface.php';
                        end;
                    };
                    field trait => array {
                        item 't/share/Php/SomethingTrait.php';
                        end;
                    };
                    field enum => array {
                        item 't/share/Php/FooEnum.php';
                        end;
                    };
                    field method_enum => array {
                        item 't/share/Php/MethodEnum.php';
                        end;
                    };
                    field class => array {
                        item 't/share/Php/Foo.php';
                        item 't/share/Php/Bar.php';
                        end;
                    };
                };
                end;
            },
            'object as expected'
        ) or diag Dumper($object);
    };

    tests 'die when file not found' => sub {
        my $object = $CLASS->new();

        ok(dies {$object->types(('non/exiting/file.php'))}, 'died with non existing file') or note($@);
        ok(lives {$object->types(('t/share/Php/FooEnum.php'))}, 'lives with existing file') or note($@);
    };
};

describe "class `$CLASS` reduce method" => sub {
    my (@excludes, $excluded, @result, $object, $exception, $warnings);

    case 'exclude enum' => sub {
        @excludes = 'enum';
        $excluded = 't/share/Php/FooEnum.php';
    };

    case 'exclude method_enum' => sub {
        @excludes = 'method_enum';
        $excluded = 't/share/Php/MethodEnum.php';
    };

    case 'exclude class' => sub {
        @excludes = 'class';
        $excluded = 't/share/Php/Foo.php';
    };

    case 'exclude interface' => sub {
        @excludes = 'interface';
        $excluded = 't/share/Php/SomethingInterface.php';
    };

    case 'exclude trait' => sub {
        @excludes = 'trait';
        $excluded = 't/share/Php/SomethingTrait.php';
    };

    tests 'reduce paths' => sub {
        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new();
                @result = $object->reduce((paths => \@paths, excludes => \@excludes));
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');
        is($excluded, not_in_set(@result), 'excluded file not in set');
    };
};

describe "class `$CLASS` reduce options" => sub {
    tests 'reduce method call' => sub {
        my @excludes = 'trait';
        my $object = $CLASS->new();

        ok(dies {$object->reduce((paths => \@paths))}, 'died with missing excludes') or note($@);
        ok(dies {$object->reduce((excludes => \@excludes))}, 'died with missing paths') or note($@);
        ok(lives {$object->reduce((paths => \@paths, excludes => \@excludes))}, 'lived with paths and excludes defined') or note($@);
    };
};

done_testing();

