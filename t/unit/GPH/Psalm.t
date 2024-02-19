#!/usr/bin/perl
package t::unit::GPH::Psalm;

use strict;
use warnings;

use Test2::V0 -target => 'GPH::Psalm';
use Test2::Tools::Spec;
use Data::Dumper;

describe "class `$CLASS`" => sub {
    tests 'it can be instantiated' => sub {
        can_ok($CLASS, 'new');
    };

    tests "mandatory config options" => sub {
        ok(dies {$CLASS->new((level => '1'))}, 'died with missing paths') or note($@);
        ok(dies {$CLASS->new((paths => []))}, 'died with missing level') or note($@);
        ok(lives {$CLASS->new((level => '1', paths => []))}, 'lives with mandatory options') or note($@);
    };
};

describe 'configuration options' => sub {
    my (%config, $level, @paths, @ignoredDirectories, @plugins);
    my ($expected_baseline, $expected_baselineCheck, $expected_ignoredDirectories, $expected_cacheDir, $expected_plugins);

    $level = 2;
    @paths = [ 'src/Service/PhraseTagService.php', 'src/Command/AbstractPhraseKeyCommand.php' ];
    @ignoredDirectories = [ '/ignored/' ];
    @plugins = [ 'Psalm\SymfonyPsalmPlugin\Plugin' ];

    case 'minimal options' => sub {
        %config = (
            level => 2,
            paths => \@paths,
        );

        $expected_baselineCheck = 'true';
        $expected_cacheDir = './psalm';
        $expected_baseline = undef;
        $expected_ignoredDirectories = undef;
        $expected_plugins = undef;
    };

    case 'config with empty arrays' => sub {
        %config = (
            level              => 2,
            paths              => \@paths,
            ignoredDirectories => [],
            plugins            => [],
        );

        $expected_baselineCheck = 'true';
        $expected_cacheDir = './psalm';
        $expected_baseline = undef;
        $expected_ignoredDirectories = undef;
        $expected_plugins = undef;
    };

    case 'maximal options' => sub {
        %config = (
            level              => 2,
            paths              => \@paths,
            ignoredDirectories => \@ignoredDirectories,
            baseline           => './baselines/psalm-baseline.xml',
            baselineCheck      => 'false',
            cacheDir           => 'var/cache',
            plugins            => \@plugins,
        );

        $expected_baseline = $config{baseline};
        $expected_baselineCheck = $config{baselineCheck};
        $expected_ignoredDirectories = \@ignoredDirectories;
        $expected_cacheDir = $config{cacheDir};
        $expected_plugins = \@plugins;
    };

    tests 'instantation' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new(%config);
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $object,
            object {
                field level => $level;
                field paths => \@paths;
                field ignoredDirectories => $expected_ignoredDirectories;
                field baseline => $expected_baseline;
                field baselineCheck => $expected_baselineCheck;
                field cacheDir => $expected_cacheDir;
                field plugins => $expected_plugins;
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
    my @paths = qw{/src/Command /src/Service /src/DependencyInjection/Configuration.php};
    my %config = (
        level              => 2,
        paths              => \@paths,
        ignoredDirectories => [ 'vendor' ],
        baseline           => 'baselines/psalm-baseline.xml',
        baselineCheck      => 'true',
        cacheDir           => './psalm',
        plugins            => [ 'Psalm\SymfonyPsalmPlugin\Plugin' ],
    );

    my $object = $CLASS->new(%config);

    tests 'compare config contents' => sub {
        my $config = $object->getConfig();
        my $mock;

        open(my $fh, '<', './t/share/Psalm/psalm.xml');

        local $/;
        $mock = <$fh>;

        close($fh);

        is($config, $mock, 'config content correct');
    };

    tests 'compare config with issue handlers content' => sub {
        my $config = $object->getConfigWithIssueHandlers('./t/share/Psalm/psalm-stub.xml', qw{MoreSpecificImplementedParamType NonExistingHandler});
        my $mock;

        open(my $fh, '<', './t/share/Psalm/psalm-issue-handlers.xml');
        {
            local $/;
            $mock = <$fh>;
        }
        close($fh);

        is($config, $mock, 'config with issue handlers content correct');
    };
};

done_testing();

