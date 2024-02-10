#!/usr/bin/perl
package t::unit::GPH::PHPMD;

use strict;
use warnings;

use Test2::V0 -target => 'GPH::PHPMD';
use Test2::Tools::Spec;

local $SIG{__WARN__} = sub {};

describe "class `$CLASS`" => sub {
    tests 'it can be instantiated' => sub {
        can_ok($CLASS, 'new');
    };

    tests 'instantation' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new('@teams/alpha', 3);
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field owner => '@teams/alpha';
                field cycloLevel => 3;
                field generator => object {
                    prop blessed => 'GPH::XMLHelper';
                };
                end;
            },
            'object as expected'
        );
    };
};

describe "class `$CLASS` config generation" => sub {
    tests 'compare config contents' => sub {
        my $object = $CLASS->new('@teams/alpha', 3);
        my $config = $object->getConfig();
        my $mock;

        open (my $fh, '<', './t/share/PHPMD/phpmd-ruleset.xml');
        {
            local $/;
            $mock = <$fh>;
        }
        close($fh);

        is($config, $mock, 'config content correct');
    };
};

done_testing();

