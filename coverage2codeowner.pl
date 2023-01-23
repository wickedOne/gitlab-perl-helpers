#!/usr/bin/perl -w
use strict;
use warnings;

use File::Basename;
use lib dirname(__FILE__) . '/lib/';

use PHPUnit;

use constant CLASSMAP_FILE => './vendor/composer/autoload_classmap.php';
use constant CODEOWNERS_FILE => './CODEOWNERS';

my $phpunit = new PHPUnit($ENV{'DEV_TEAM'}, CODEOWNERS_FILE, CLASSMAP_FILE, $ENV{'MIN_COVERAGE'});

exit $phpunit->Parse();