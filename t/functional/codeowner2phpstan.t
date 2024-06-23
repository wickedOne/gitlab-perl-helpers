#!/usr/bin/perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Spec;

use Data::Dumper;
use File::Temp;

BEGIN {
    @ENV{"DEV_TEAM", "CODEOWNERS", "EXCLUDE_PATHS", "PHPSTAN_LEVEL", "PHPSTAN_IGNORED_DIRS", "PHPSTAN_INCLUDES", "PHPSTAN_BASELINE", "PHPSTAN_CACHE_DIR", "PHPSTAN_THREADS"} = ('@teams/alpha', './t/share/Gitlab/CODEOWNERS-functional', '.gitlab-ci.yml', '1', "/ignored/", '/includes/', './baselines/baseline.xml', '/tmp', '6');
}

describe "generate PHPStan config" => sub {
    tests "compare config" => sub {
        my ($c, $fh, $file, $mock, $stdout, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $file = File::Temp::tmpnam();
                $c = system("$^X scripts/codeowner2phpstan.pl > $file");
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');
        is($c, 0, 'program exited with successful exit code', $c);

        open $fh, '<', './t/share/PHPStan/phpstan-functional.neon' or die $!;
        $mock = do {
            local $/;
            <$fh>
        };
        close($fh);

        open $fh, '<', $file or die $!;
        $stdout = do {
            local $/;
            <$fh>
        };
        close($fh);

        is($stdout, $mock, 'config content correct') or diag Dumper($stdout);

        unlink($file);
    };
};

done_testing();

