#!/usr/bin/perl -w
package t::unit::GPH::PHPUnit;

use strict;
use warnings;

use Test2::V0 -target => 'GPH::PHPUnit';
use Test2::Tools::Spec;

use Data::Dumper;

use constant CODEOWNERS_FILE => './t/share/Gitlab/CODEOWNERS';
use constant CLASSMAP_FILE => './t/share/Composer/autoload_classmap.php';
use constant PHPUNIT_OUTPUT_FILE => './t/share/PHPUnit/phpunit-output.txt';
use constant PHPUNIT_BASELINE_FILE => './t/share/PHPUnit/phpunit-baseline.txt';

describe "class `$CLASS`" => sub {
    tests 'it can be instantiated' => sub {
        can_ok($CLASS, 'new');
    };

    tests 'dies without correct config' => sub {
        ok(dies {$CLASS->new(('codeowners' => CODEOWNERS_FILE, classmap => CLASSMAP_FILE))}, 'died with missing owner option') or note($@);
        ok(dies {$CLASS->new(('owner' => '@teams/alpha', classmap => CLASSMAP_FILE))}, 'died with missing codeowners option') or note($@);
        ok(dies {$CLASS->new(('owner' => '@teams/alpha', 'codeowners' => CODEOWNERS_FILE))}, 'died with missing classmap option') or note($@);
        ok(lives {$CLASS->new(('owner' => '@teams/alpha', 'codeowners' => CODEOWNERS_FILE, classmap => CLASSMAP_FILE))}, 'lives with mandatory config settings') or note($@);
    };

    tests "baseline file not found" => sub {
        ok(dies {$CLASS->new((codeowners => CODEOWNERS_FILE, owner => '@teams/alpha', baseline => 'foo.txt'))}, 'died with baseline not found') or note($@);
        ok(lives {$CLASS->new((codeowners => CODEOWNERS_FILE, owner => '@teams/alpha', classmap => CLASSMAP_FILE, baseline => PHPUNIT_BASELINE_FILE))}, 'lives with correct baseline') or note($@);
    };
};

describe 'configuration options' => sub {
    my ($owner, %config, $expected_threshold, @expected_baseline);
    $owner = '@teams/alpha';

    case 'minimal options' => sub {
        %config = (
            owner      => $owner,
            classmap   => CLASSMAP_FILE,
            codeowners => CODEOWNERS_FILE,
            baseline   => undef,
        );

        $expected_threshold = 0.0;
        @expected_baseline = qw();
    };

    case 'maximal options' => sub {
        %config = (
            owner      => $owner,
            classmap   => CLASSMAP_FILE,
            codeowners => CODEOWNERS_FILE,
            threshold  => 95.5,
            excludes   => [ '.gitlab-ci.yml' ],
            baseline   => PHPUNIT_BASELINE_FILE
        );

        $expected_threshold = 95.5;
        @expected_baseline = qw{/src/Service/Provider/ /src/Mapper/};
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
                field owner => $owner;
                field threshold => $expected_threshold;
                field baseline => \@expected_baseline;
                field classreport => {};
                field stats => object {
                    prop blessed => 'GPH::PHPUnit::Stats';
                };
                field gitlab => object {
                    prop blessed => 'GPH::Gitlab';
                };
                field composer => object {
                    prop blessed => 'GPH::Composer';
                };
                end;
            },
            'object as expected',
            Dumper($object)
        );
    };
};

describe "parsing phpunit report output" => sub {
    my ($expected_exit_code, %config);

    %config = (
        owner      => '@teams/alpha',
        classmap   => CLASSMAP_FILE,
        codeowners => CODEOWNERS_FILE,
        excludes   => [ '.gitlab-ci.yml' ],
        baseline   => PHPUNIT_BASELINE_FILE
    );

    case 'failure' => sub {
        $config{threshold} = 100;
        $expected_exit_code = 1;
    };

    case 'success' => sub {
        $config{threshold} = 95;
        $expected_exit_code = 0;
    };

    tests "test `$CLASS` exit code" => sub {
        my ($stdout, $object, $exception, $warnings, $exit_code);

        $exception = dies {
            $warnings = warns {
                local *ARGV;
                open *ARGV, '<', PHPUNIT_OUTPUT_FILE or die "can't open PHPUNIT_OUTPUT_FILE";

                local *STDOUT;
                open *STDOUT, '>', \$stdout;
                $object = $CLASS->new(%config);
                $exit_code = $object->parse();

                close *ARGV;
                close *STDOUT;
            };
        };

        is($exception, undef, 'no exception thrown', Dumper($object));
        is($warnings, 0, 'no warnings generated');
        is($exit_code, $expected_exit_code, 'exit code correct', $stdout);
    };
};

done_testing();
