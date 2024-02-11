#!/usr/bin/perl -w
package t::unit::GPH::Infection;

use strict;
use warnings;

use Test2::V0 -target => 'GPH::Infection';
use Test2::Tools::Spec;

local $SIG{__WARN__} = sub {};

describe "class `$CLASS`" => sub {
    tests 'it can be instantiated' => sub {
        can_ok($CLASS, 'new');
    };

    tests "mandatory config options" => sub {
        ok(dies{$CLASS->new((msi => '9.0'))}, 'died with missing covered') or note ($@);
        ok(dies{$CLASS->new((covered => '9.0'))}, 'died with missing msi') or note ($@);
        ok(lives{$CLASS->new((msi => '9.0', covered => '9.0'))}, 'lives with mandatory options') or note ($@);
    };
};

describe "class `$CLASS` instantiation values" => sub {
    my ($code, $expected_code);

    case 'default escapee exit code' => sub {
        $code = undef;
        $expected_code = 8;
    };

    case 'custom escapee exit code' => sub {
        $code = 3;
        $expected_code = 3;
    };

    tests instantiation => sub {
        my ($object, $exception, $warnings, $exit_code);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((msi => '9.0', covered => '5.0', exit_code => $code));
                $exit_code = $object->{code};
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');
        is($exit_code, $expected_code, 'expected code returned');

        is($object,
            object {
                field msi => '9.0';
                field covered => '5.0';
                field "code" => $expected_code;
                end;
            },
            "object as expected",
        );
    };
};

describe 'test parse' => sub {
    my (%config, $msi, $covered, $escapees, $output_score, $output_msi, $expected_code);

    case 'msi ok, covered ok' => sub {
        %config = (
            msi     => '90',
            covered => '95',
        );

        $escapees = 0;
        $output_score = '95';
        $output_msi = '95';
        $expected_code = 0;
    };

    case 'msi not ok, covered not ok' => sub {
        %config = (
            msi     => '100',
            covered => '100',
        );

        $escapees = 0;
        $output_score = '95';
        $output_msi = '95';
        $expected_code = 1;
    };

    case 'msi ok, covered not ok' => sub {
        %config = (
            msi     => '95',
            covered => '100',
        );

        $escapees = 0;
        $output_score = '95';
        $output_msi = '95';
        $expected_code = 1;
    };

    case 'msi not ok, covered ok' => sub {
        %config = (
            msi     => '100',
            covered => '80',
        );

        $escapees = 0;
        $output_score = '95';
        $output_msi = '95';
        $expected_code = 1;
    };

    case 'msi ok, covered ok, escapees' => sub {
        %config = (
            msi     => '95',
            covered => '95',
        );

        $escapees = 1;
        $output_score = '100';
        $output_msi = '100';
        $expected_code = 8;
    };

    tests 'parse infection output' => sub {
        my ($stdout, $object, $exception, $warnings, $exit_code);

        my $stdin = "
121 mutations were generated:
     121 mutants were killed
       0 mutants were configured to be ignored
       0 mutants were not covered by tests
       ${escapees} covered mutants were not detected
       0 errors were encountered
       0 syntax errors were encountered
       0 time outs were encountered
       0 mutants required more time than configured

Metrics:
         Mutation Score Indicator (MSI): ${output_score}%
         Mutation Code Coverage: 100%
         Covered Code MSI: ${output_msi}%
";

        $exception = dies {
            $warnings = warns {
                local *ARGV;
                local *STDOUT;

                open *ARGV, '<', \$stdin or die "no can do $!";
                open *STDOUT, '>', \$stdout;

                $object = $CLASS->new(%config);
                $exit_code = $object->parse();

                close *ARGV;
                close *STDOUT;
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');
        is($exit_code, $expected_code, 'expected code returned');

        if ($expected_code == 3 and $escapees > 0) {
            like($stdout, '\[warning\]', 'warning');
        }
    }
};

done_testing;