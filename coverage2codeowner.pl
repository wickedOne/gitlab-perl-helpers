#!/usr/bin/perl -w
use strict;
use warnings;

use File::Basename;
use lib dirname(__FILE__) . '/lib/';

use PHPUnit;

use constant CLASSMAP_FILE => './vendor/composer/autoload_classmap.php';
use constant CODEOWNERS_FILE => './CODEOWNERS';

my $owner  = $ENV{'DEV_TEAM'} or die "please define owner in DEV_TEAM env var";

my $coverage = $ENV{'MIN_COVERAGE'} || 0.0;

my $paths = $ENV{'EXCLUDE_PATHS'} || '';
my @excludes = split /,/, $paths;

my $phpunit = PHPUnit->new($owner, CODEOWNERS_FILE, CLASSMAP_FILE, $coverage, @excludes);

exit $phpunit->Parse();