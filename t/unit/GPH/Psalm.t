#!/usr/bin/perl
package t::unit::GPH::Psalm;

use strict;
use warnings;

use Test2::V0 -target => 'GPH::Psalm';
use Test2::Tools::Spec;
use Data::Dumper;

local $SIG{__WARN__} = sub {};

describe "class `$CLASS`" => sub {
    tests 'it can be instantiated' => sub {
        can_ok($CLASS, 'new');
    };
};

describe 'configuration options' => sub {
    my ($level, @paths, $baseline, $baselineCheck, @ignoredDirectories, $cacheDir, @plugins);
    my ($expected_baseline, $expected_baselineCheck, @expected_ignoredDirectories, $expected_cacheDir, @expected_plugins);

    $level = 2;
    @paths = qw[src/Service/PhraseTagService.php src/Command/AbstractPhraseKeyCommand.php];

    case 'minimal options' => sub {
        $baseline = undef;
        $baselineCheck = undef;
        @ignoredDirectories = undef;
        $cacheDir = undef;
        @plugins = undef;
        $expected_baselineCheck = 'true';
        $expected_cacheDir = './psalm';
        $expected_baseline = undef;
        @expected_ignoredDirectories = undef;
        @expected_plugins = undef;
    };

    case 'maximal options' => sub {
        $baseline = './baselines/psalm-baseline.xml';
        $baselineCheck = 'false';
        @ignoredDirectories = qw{/ignored/};
        $cacheDir = 'var/cache';
        @plugins = qw{Psalm\SymfonyPsalmPlugin\Plugin};
        $expected_baseline = $baseline;
        $expected_baselineCheck = $baselineCheck;
        @expected_ignoredDirectories = @ignoredDirectories;
        $expected_cacheDir = $cacheDir;
        @expected_plugins = @plugins;
    };

    tests 'instantation' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new($level, \@paths, $baseline, $baselineCheck, \@ignoredDirectories, $cacheDir, \@plugins);
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field level => $level;
                field paths => \@paths;
                field ignoredDirectories => \@expected_ignoredDirectories;
                field baseline => $expected_baseline;
                field baselineCheck => $expected_baselineCheck;
                field cacheDir => $expected_cacheDir;
                field plugins => \@expected_plugins;
                field generator => object {
                    prop blessed => 'GPH::XMLHelper';
                };
                etc;
            },
            'object as expected',
            Dumper($object)
        );
    };
};

describe "class `$CLASS` config generation" => sub {
    my @paths = qw{/src/Command /src/Service};
    my $object = $CLASS->new(2, \@paths, 'baselines/psalm-baseline.xml', 'true', ['vendor'], './psalm', ['Psalm\SymfonyPsalmPlugin\Plugin']);

    tests 'compare config contents' => sub {
        my $config = $object->getConfig();
        my $mock;

        open (my $fh, '<', './t/share/Psalm/psalm.xml');

        local $/;
        $mock = <$fh>;

        close($fh);

        is($config, $mock, 'config content correct');
    };

    tests 'compare config with issue handlers content' => sub {
        my $config = $object->getConfigWithIssueHandlers('./t/share/Psalm/psalm-stub.xml', qw{MoreSpecificImplementedParamType});
        my $mock;

        open (my $fh, '<', './t/share/Psalm/psalm-issue-handlers.xml');
        {
            local $/;
            $mock = <$fh>;
        }
        close($fh);

        is($config, $mock, 'config with issue handlers content correct');
    };
};

done_testing();

