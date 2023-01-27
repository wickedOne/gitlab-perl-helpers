#!/usr/bin/perl -w
use strict;
use warnings;

use File::Basename;
use lib dirname(__FILE__) . '/lib/';

use PHPUnit;

use constant CLASSMAP_FILE => './vendor/composer/autoload_classmap.php';
use constant CODEOWNERS_FILE => './CODEOWNERS';

my $str = $ENV{'EXCLUDE_PATHS'} || '';
my @excludes = split /,/, $str;

my $phpunit = PHPUnit->new($ENV{'DEV_TEAM'}, CODEOWNERS_FILE, CLASSMAP_FILE, $ENV{'MIN_COVERAGE'}, @excludes);

exit $phpunit->Parse();