#!/usr/bin/perl -w
use strict;
use warnings FATAL => 'all';

use File::Basename;
use lib dirname(__FILE__) . '/lib/';

use GPH::PHPUnit;

my $owner  = $ENV{'DEV_TEAM'} or die "please define owner in DEV_TEAM env var";
my @excludes = split /,/, ($ENV{'EXCLUDE_PATHS'} || '');
my %config = (
    owner      => $owner,
    classmap   => './vendor/composer/autoload_classmap.php',
    codeowners => './CODEOWNERS',
    threshold  =>  $ENV{'MIN_COVERAGE'},
    excludes   => \@excludes,
    baseline   => $ENV{'PHPUNIT_BASELINE'}
);

my $phpunit = GPH::PHPUnit->new(%config);

exit $phpunit->parse();