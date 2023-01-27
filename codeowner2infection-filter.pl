#!/usr/bin/perl -w
use strict;
use warnings;

use File::Basename;
use lib dirname(__FILE__) . '/lib/';

use Gitlab;

my $str = $ENV{'EXCLUDE_PATHS'} || '';
my @excludes = split /,/, $str;

my $gitlab = Gitlab->new('./CODEOWNERS', $ENV{'DEV_TEAM'}, @excludes);

print $gitlab->GetCommaSeparatedPathList();