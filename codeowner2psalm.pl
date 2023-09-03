#!/usr/bin/perl -w
use strict;
use warnings FATAL => 'all';

use File::Basename;
use lib dirname(__FILE__) . '/lib/';

use Gitlab;
use Psalm;

use constant CODEOWNERS_FILE => './CODEOWNERS';
use constant PSALM_CONFIG => './psalm.xml';

my $owner  = $ENV{'DEV_TEAM'} or die "please define owner in DEV_TEAM env var";

my $exclude = $ENV{'EXCLUDE_PATHS'} || '';
my @excludes = split /,/, $exclude;

my $level = $ENV{'PSALM_LEVEL'} || 4;
my $baseline = $ENV{'PSALM_BASELINE'} || undef;
my $baselineCheck = $ENV{'PSALM_BASELINE_CHECK'} || undef;
my $cacheDir = $ENV{'PSALM_CACHE_DIR'} || undef;
my $ignore = $ENV{'PSALM_IGNORED_DIRS'} || '';
my @ignored = split /,/, $ignore;
my $plugin = $ENV{'PSALM_PLUGINS'} || '';
my @plugins = split /,/, $plugin;
my $clone = defined($ENV{'PSALM_CLONE_HANDLERS'}) ? $ENV{'PSALM_CLONE_HANDLERS'} : 1;

my $gitlab = Gitlab->new(CODEOWNERS_FILE, $owner, @excludes);
my $psalm = Psalm->new($level, $gitlab->GetPathsReference(), $baseline, $baselineCheck, \@ignored, $cacheDir, \@plugins);

if ($clone) {
    my $excludeHandlers = $ENV{'PSALM_EXCLUDE_HANDLERS'} || '';
    my @blacklist = split /,/, $excludeHandlers;

    print $psalm->GetConfigWithIssueHandlers(PSALM_CONFIG, @blacklist);
} else {
    print $psalm->GetConfig();
}
