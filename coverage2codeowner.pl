#!/usr/bin/perl -w
use strict;
use warnings FATAL => 'all';

use File::Basename;
use lib dirname(__FILE__) . '/lib/';

use GPH::PHPUnit;

use constant CLASSMAP_FILE => './vendor/composer/autoload_classmap.php';
use constant CODEOWNERS_FILE => './CODEOWNERS';

my $owner  = $ENV{'DEV_TEAM'} or die "please define owner in DEV_TEAM env var";

my $coverage = $ENV{'MIN_COVERAGE'} || 0.1;

my $paths = $ENV{'EXCLUDE_PATHS'} || '';
my @excludes = split /,/, $paths;

my $baseline = $ENV{'PHPUNIT_BASELINE'} || undef;

my $phpunit = GPH::PHPUnit->new($owner, CODEOWNERS_FILE, CLASSMAP_FILE, $coverage, \@excludes, $baseline);

exit $phpunit->parse();