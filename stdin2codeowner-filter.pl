#!/usr/bin/perl -w
use strict;
use warnings FATAL => 'all';

use File::Basename;
use lib dirname(__FILE__) . '/lib/';

use Gitlab;

use constant CODEOWNERS_FILE => './CODEOWNERS';

my $owner  = $ENV{'DEV_TEAM'} or die "please define owner in DEV_TEAM env var";

my $paths = $ENV{'EXCLUDE_PATHS'} || '';
my @excludes = split /,/, $paths;

my $gitlab = Gitlab->new(CODEOWNERS_FILE, $owner, @excludes);

print $gitlab->IntersectToCommaSeparatedPathList(<STDIN>);