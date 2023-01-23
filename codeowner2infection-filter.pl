#!/usr/bin/perl -w
use strict;
use warnings;

use File::Basename;
use lib dirname(__FILE__) . '/lib/';

use Gitlab;

my $gitlab = new Gitlab('./CODEOWNERS', $ENV{'DEV_TEAM'});

print $gitlab->GetInfectionFilter();