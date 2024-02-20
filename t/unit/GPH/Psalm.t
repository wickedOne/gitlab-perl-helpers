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
    my (%config, $level, @paths, @ignored_directories, @plugins);
    my ($expected_baseline, $expected_baseline_check, $expected_ignored_directories, $expected_cache_dir, $expected_plugins);

    $level = 2;
    @paths = [ 'src/Service/PhraseTagService.php', 'src/Command/AbstractPhraseKeyCommand.php' ];
    @ignored_directories = [ '/ignored/', '/ignored.php' ];
    @plugins = [ 'Psalm\SymfonyPsalmPlugin\Plugin' ];

    case 'minimal options' => sub {
        %config = (
            level => 2,
            paths => \@paths,
        );

        $expected_baseline_check = 'true';
        $expected_cache_dir = './psalm';
        $expected_baseline = undef;
        $expected_ignored_directories = undef;
        $expected_plugins = undef;
    };

    case 'config with empty arrays' => sub {
        %config = (
            level               => 2,
            paths               => \@paths,
            ignored_directories => [],
            plugins             => [],
        );

        $expected_baseline_check = 'true';
        $expected_cache_dir = './psalm';
        $expected_baseline = undef;
        $expected_ignored_directories = undef;
        $expected_plugins = undef;
    };

    case 'maximal options' => sub {
        %config = (
            level               => 2,
            paths               => \@paths,
            ignored_directories => \@ignored_directories,
            baseline            => './baselines/psalm-baseline.xml',
            baseline_check      => 'false',
            cache_dir           => 'var/cache',
            plugins             => \@plugins,
        );

        $expected_baseline = $config{baseline};
        $expected_baseline_check = $config{baseline_check};
        $expected_ignored_directories = \@ignored_directories;
        $expected_cache_dir = $config{cache_dir};
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
                field ignored_directories => $expected_ignored_directories;
                field baseline => $expected_baseline;
                field baseline_check => $expected_baseline_check;
                field cache_dir => $expected_cache_dir;
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
        level               => 2,
        paths               => \@paths,
        ignored_directories => [ 'vendor', 'example.php' ],
        baseline            => 'baselines/psalm-baseline.xml',
        baseline_check      => 'true',
        cache_dir           => './psalm',
        plugins             => [ 'Psalm\SymfonyPsalmPlugin\Plugin' ],
    );

    tests 'compare max config contents' => sub {
        my $object = $CLASS->new(%config);
        my $config = $object->getConfig();
        my $mock;

        open(my $fh, '<', './t/share/Psalm/psalm-max.xml');

        local $/;
        $mock = <$fh>;

        close($fh);

        is($config, $mock, 'config content correct');
    };

    tests 'compare min config contents' => sub {
        my $object = $CLASS->new((level => 2, paths => \@paths));

        my $config = $object->getConfig();
        my $mock;

        open(my $fh, '<', './t/share/Psalm/psalm-min.xml');

        local $/;
        $mock = <$fh>;

        close($fh);

        is($config, $mock, 'config content correct');
    };

    tests 'compare config with issue handlers content' => sub {
        my $object = $CLASS->new(%config);

        my @blacklist = qw{MoreSpecificImplementedParamType NonExistingHandler};
        $blacklist[2] = undef;

        my $config = $object->getConfigWithIssueHandlers('./t/share/Psalm/psalm-stub.xml', @blacklist);
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

