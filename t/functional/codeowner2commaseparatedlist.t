#!/usr/bin/perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Spec;

use Data::Dumper;
use File::Temp;

BEGIN {
    @ENV{"DEV_TEAM", "EXCLUDE_PATHS", "CODEOWNERS"} = ('@teams/alpha', '.gitlab-ci.yml', './t/share/Gitlab/CODEOWNERS-functional');
}

describe "generate phpmd config" => sub {
    tests "compare config" => sub {
        my ($c, $fh, $exception, $warnings, $stdout, $file);

        $exception = dies {
            $warnings = warns {
                $file = File::Temp::tmpnam();
                $c = system("$^X scripts/codeowner2commaseparatedlist.pl > $file");
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');
        is($c, 0, 'program exited with successful exit code', $c);

        open $fh, '<', $file or die $!;
        $stdout = do {
            local $/;
            <$fh>
        };
        close($fh);

        is($stdout, '/src/Command/,/src/Service/', 'config content correct') or diag Dumper($stdout);

        unlink($file);

    };
};

done_testing();

