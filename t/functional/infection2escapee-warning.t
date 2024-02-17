#!/usr/bin/perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Spec;

use Data::Dumper;

BEGIN {
    @ENV{"MIN_MSI", "MIN_COVERED_MSI"} = ('90', '95');
}

describe "parse infection output" => sub {
    tests "parse" => sub {
        my ($c, $fh, $file, $mock, $stdout, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $file = File::Temp::tmpnam();
                $c = system("/bin/cat ./t/share/Infection/infection-output-functional.txt | ./infection2escapee-warning.pl > $file");
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');
        # system times the exit code by 256
        is($c, 256 * 8, 'program exited with correct exit code', $c);

        open $fh, '<', './t/share/Infection/infection-report-functional.txt' or die $!;
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

        is($stdout, $mock, 'report output correct') or diag Dumper($stdout);

        unlink($file);
    };
};

done_testing();

