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

    tests 'dies without correct config' => sub {
        ok(dies{$CLASS->new(('level' => 4))}, 'died with paths missing') or note ($@);
        ok(dies{$CLASS->new(('paths' => []))}, 'died with level missing') or note ($@);
        ok(lives{$CLASS->new(('level' => 4, 'paths' => []))}, 'lives with mandatory config settings') or note ($@);
    };
};

describe "class `$CLASS` instantiation values" => sub {
    my (@paths, %config, @ignoredDirectories, @includes, $config_path);
    my ($expected_level, $expected_baseline, $expected_ignoredDirectories, $expected_cacheDir, $expected_includes, $expected_threads);

    @paths = qw[src/Service/PhraseTagService.php src/Command/AbstractPhraseKeyCommand.php];

    case 'minimal config' => sub {
        %config = (
            level => 4,
            paths => \@paths
        );

        $expected_level = 4;
        $expected_baseline = undef;
        $expected_ignoredDirectories = undef;
        $expected_cacheDir = 'var';
        $expected_includes = undef;
        $expected_threads = 4;
        $config_path = './t/share/PHPStan/phpstan-min.neon';
    };

    case 'maximum config' => sub {
        @ignoredDirectories = qw(/ignored/);
        @includes = qw(/includes/);

        %config = (
            level              => 1,
            paths              => \@paths,
            baseline           => './baselines/baseline.xml',
            ignoredDirectories => \@ignoredDirectories,
            cacheDir           => '/tmp',
            includes           => \@includes,
            threads            => 6
        );

        $expected_level = 1;
        $expected_baseline = './baselines/baseline.xml';
        $expected_ignoredDirectories = \@ignoredDirectories;
        $expected_cacheDir = '/tmp';
        $expected_includes = \@includes;
        $expected_threads = 6;
        $config_path = './t/share/PHPStan/phpstan-max.neon';
    };

    tests 'instantiation' => sub {
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
                field level => $expected_level;
                field paths => \@paths;
                field ignoredDirectories => $expected_ignoredDirectories;
                field baseline => $expected_baseline;
                field cacheDir => $expected_cacheDir;
                field includes => $expected_includes;
                field threads => $expected_threads;
                end;
            },
            'object as expected',
            Dumper($object)
        );
    };

    tests 'compare config contents' => sub {
        my ($object, $exception, $warnings, $neon, $mock);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new(%config);
                $neon = $object->getConfig();
            };
        };

        is($exception, undef, 'no exception thrown', Dumper($object));
        is($warnings, 0, 'no warnings generated', Dumper($object));

        open (my $fh, '<', $config_path);
        {
            local $/;
            $mock = <$fh>;
        }
        close($fh);

        is($neon, $mock, 'config content correct', Dumper($object));
    }
};

done_testing();

