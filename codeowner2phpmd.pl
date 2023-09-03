#!/usr/bin/perl -w
use strict;
use warnings FATAL => 'all';

use File::Basename;
use lib dirname(__FILE__) . '/lib/';

use PHPMD;

my $owner = $ENV{'DEV_TEAM'} or die "please define owner in DEV_TEAM env var";
my $cycloLevel = $ENV{'CYCLO_LEVEL'} || 10;

my $phpmd = PHPMD->new($owner, $cycloLevel);

print $phpmd->GetConfig();