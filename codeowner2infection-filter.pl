#!/usr/bin/perl -w
use strict;
use warnings;

use File::Basename;
use lib dirname(__FILE__) . '/lib/';

use Gitlab;

my $gitlab = Gitlab->new('./CODEOWNERS', $ENV{'DEV_TEAM'});

print $gitlab->GetInfectionFilter();