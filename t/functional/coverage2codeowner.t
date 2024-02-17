#!/usr/bin/perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Spec;

use Data::Dumper;

BEGIN {
    @ENV{"DEV_TEAM", "EXCLUDE_PATHS", "CODEOWNERS", "CLASSMAP"} = ('@teams/alpha', '.gitlab-ci.yml', './t/share/Gitlab/CODEOWNERS-functional', './t/share/Composer/autoload_classmap.php');
}

describe "parse phpunit output" => sub {
    tests "parse" => sub {
        my ($c, $fh, $file, $mock, $stdout, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $file = File::Temp::tmpnam();
                $c = system("/bin/cat ./t/share/PHPUnit/phpunit-output-functional.txt | ./coverage2codeowner.pl > $file");
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');
        is($c, 0, 'program exited with successful exit code', $c);

        open $fh, '<', './t/share/PHPUnit/phpunit-report-functional.txt' or die $!;
        $mock = do {
            local $/;
            <$fh>
        };
        close($fh);

        open $fh, '<', $file or die $!;
        while (<$fh>) {
            # replacing datetime of the report until someone tells me how to mock it
            $_ = '  2024-02-17 08:49:26' . "\n" if $. == 2;
            $stdout .= $_;
        }
        close($fh);

        is($stdout, $mock, 'report output correct') or diag Dumper($stdout);

        unlink($file);
    };
};

done_testing();

