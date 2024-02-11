#!/usr/bin/perl -w
package t::unit::GPH::PHPUnit;

use strict;
use warnings;

use Test2::V0 -target => 'GPH::PHPUnit';
use Test2::Tools::Spec;

use Data::Dumper;
use Readonly;

Readonly my $CODEOWNERS_FILE => './t/share/Gitlab/CODEOWNERS';
Readonly my $CLASSMAP_FILE => './t/share/Composer/autoload_classmap.php';
Readonly my $PHPUNIT_OUTPUT_FILE => './t/share/PHPUnit/phpunit-output.txt';
Readonly my $PHPUNIT_BASELINE_FILE => './t/share/PHPUnit/phpunit-baseline.txt';

local $SIG{__WARN__} = sub {};

describe "class `$CLASS`" => sub {
    tests 'it can be instantiated' => sub {
        can_ok($CLASS, 'new');
    };
};

describe 'configuration options' => sub {
    my ($owner, $threshold, @excludes, $baseline);
    my ($expected_threshold, @expected_baseline);

    $owner = '@teams/alpha';

    case 'minimal options' => sub {
        $threshold = undef;
        @excludes = qw();
        $baseline = undef;
        $expected_threshold = 0.0;
        @expected_baseline = qw();
    };

    case 'maximal options' => sub {
        $threshold = 95.5;
        @excludes = qw{.gitlab-ci.yml};
        $baseline = $PHPUNIT_BASELINE_FILE;
        $expected_threshold = $threshold;
        @expected_baseline = qw{/src/Service/Provider/ /src/Mapper/};
    };

    tests 'instantation' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new($owner, $CODEOWNERS_FILE, $CLASSMAP_FILE, $threshold, \@excludes, $baseline);
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
                    prop blessed =>'GPH::PHPUnit::Stats';
                };
                field gitlab => object {
                    prop blessed =>'GPH::Gitlab';
                };
                field composer => object {
                    prop blessed =>'GPH::Composer';
                };
                end;
            },
            'object as expected',
            Dumper($object)
        );
    };
};

describe "parsing phpunit report output" => sub {
    my ($threshold, $expected_exit_code);

    case 'failure' => sub {
        $threshold = 100;
        $expected_exit_code = 1;
    };

    case 'success' => sub {
        $threshold = 95;
        $expected_exit_code = 0;
    };

    tests "test `$CLASS` exit code" => sub {
        my ($stdout, $object, $exception, $warnings, $exit_code);
        my @excludes = qw{.gitlab-ci.yml};


        $exception = dies {
            $warnings = warns {
                local *ARGV;
                open *ARGV, '<', $PHPUNIT_OUTPUT_FILE or die "can't open ${PHPUNIT_OUTPUT_FILE}";

                $object = $CLASS->new('@teams/alpha', $CODEOWNERS_FILE, $CLASSMAP_FILE, $threshold, \@excludes, $PHPUNIT_BASELINE_FILE);
                $exit_code = $object->parse();

                close *ARGV;
            };
        };

        is($exception, undef, 'no exception thrown', Dumper($object));
        is($warnings, 0, 'no warnings generated');
        is($exit_code, $expected_exit_code, 'exit code correct', $stdout);
    };
};

done_testing();
