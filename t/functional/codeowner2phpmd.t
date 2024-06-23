#!/usr/bin/perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Spec;

use Data::Dumper;
use File::Temp;

BEGIN {
    @ENV{"DEV_TEAM", "CYCLO_LEVEL"} = ('@teams/alpha', "3");
}

describe "generate phpmd config" => sub {
    tests "compare config" => sub {
        my ($c, $fh, $file, $mock, $stdout, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $file = File::Temp::tmpnam();
                $c = system("$^X scripts/codeowner2phpmd.pl > $file");
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');
        is($c, 0, 'program exited with successful exit code', $c);

        open $fh, '<', './t/share/PHPMD/phpmd-ruleset-functional.xml' or die $!;
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

