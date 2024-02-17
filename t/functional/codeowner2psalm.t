#!/usr/bin/perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Spec;

use Data::Dumper;
use File::Temp;

BEGIN {
    @ENV{"DEV_TEAM", "EXCLUDE_PATHS", "CODEOWNERS", "PSALM_BASE_CONFIG", "PSALM_IGNORED_DIRS", "PSALM_PLUGINS", "PSALM_LEVEL", "PSALM_BASELINE", "PSALM_EXCLUDE_HANDLERS"} = ('@teams/alpha', '.gitlab-ci.yml', './t/share/Gitlab/CODEOWNERS-functional', './t/share/Psalm/psalm-stub.xml', 'vendor', 'Psalm\SymfonyPsalmPlugin\Plugin', '2', 'baselines/psalm-baseline.xml', 'MoreSpecificImplementedParamType');
}

describe "generate Psalm config" => sub {
    tests "compare config" => sub {
        my ($c, $fh, $file, $mock, $stdout, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $file = File::Temp::tmpnam();
                $c = system("$^X codeowner2psalm.pl > $file");
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');
        is($c, 0, 'program exited with successful exit code', $c);

        open $fh, '<', './t/share/Psalm/psalm-functional.xml' or die $!;
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

