#!/usr/bin/perl
package t::unit::GPH::PHPStan;

use strict;
use warnings;

use Test2::V0 -target => 'GPH::PHPStan';
use Test2::Tools::Spec;
use Data::Dumper;

local $SIG{__WARN__} = sub {};

describe "class `$CLASS`" => sub {
    tests 'it can be instantiated' => sub {
        can_ok($CLASS, 'new');
    };
};

describe "class `$CLASS` instantiation values" => sub {
    my ($level, @paths, $baseline, @ignoredDirectories, $cacheDir, @includes, $threads);
    my ($expected_level, $expected_baseline, @expected_ignoredDirectories, $expected_cacheDir, @expected_includes, $expected_threads);

    @paths = qw[src/Service/PhraseTagService.php src/Command/AbstractPhraseKeyCommand.php];

    case 'minimal config' => sub {
        $level = 4;
        $baseline = undef;
        @ignoredDirectories = undef;
        $cacheDir = undef;
        @includes = undef;
        $threads = undef;
        $expected_level = $level;
        $expected_baseline = undef;
        @expected_ignoredDirectories = undef;
        $expected_cacheDir = 'var';
        @expected_includes = undef;
        $expected_threads = 4;
    };

    case 'maximum config' => sub {
        $level = 1;
        $baseline = './baselines/baseline.xml';
        @ignoredDirectories = qw(/ignored/);
        $cacheDir = '/tmp';
        @includes = qw(/includes/);
        $threads = 6;
        $expected_level = $level;
        $expected_baseline = $baseline;
        @expected_ignoredDirectories = @ignoredDirectories;
        $expected_cacheDir = $cacheDir;
        @expected_includes = @includes;
        $expected_threads = $threads;
    };

    tests 'instantiation' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new($level, \@paths, $baseline, \@ignoredDirectories, $cacheDir, \@includes, $threads);
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');
        is(
            $object,
            object {
                field level => $expected_level;
                field paths => \@paths;
                field ignoredDirectories => \@expected_ignoredDirectories;
                field baseline => $expected_baseline;
                field cacheDir => $expected_cacheDir;
                field includes => \@expected_includes;
                field threads => $expected_threads;
                end;
            },
            'object as expected'
        );
    }
};

describe 'test config generation' => sub {
    my ($object, $exception, $warnings, $config);
    my @paths = qw[src/Service/PhraseTagService.php src/Command/AbstractPhraseKeyCommand.php];
    my @ignores = qw[/ignored/];
    my @includes = qw[/includes/];
    my $mock;

    $object = $CLASS->new(1, \@paths, './baselines/baseline.xml', \@ignores, 'tmp', \@includes, 3);

    tests 'compare config contents' => sub {
        $exception = dies {
            $warnings = warns {
                $config = $object->getConfig();
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        open (my $fh, '<', './t/share/PHPStan/phpstan.neon');
        {
            local $/;
            $mock = <$fh>;
        }
        close($fh);

        is($config, $mock, 'config content correct');
    }
};

done_testing();

