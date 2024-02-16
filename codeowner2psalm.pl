#!/usr/bin/perl -w
use strict;
use warnings FATAL => 'all';

use File::Basename;
use lib dirname(__FILE__) . '/lib/';

use GPH::Gitlab;
use GPH::Psalm;

my $owner = $ENV{'DEV_TEAM'} or die "please define owner in DEV_TEAM env var";
my @excludes = split /,/, ($ENV{'EXCLUDE_PATHS'} || '');

my %gitlabConfig = (
    owner      => $owner,
    codeowners => './CODEOWNERS',
    excludes   => \@excludes,
);

my $gitlab = GPH::Gitlab->new(%gitlabConfig);

my @ignored = split /,/, ($ENV{'PSALM_IGNORED_DIRS'} || '');
my @plugins = split /,/, ($ENV{'PSALM_PLUGINS'} || '');
my $clone = (defined($ENV{'PSALM_CLONE_HANDLERS'}) ? $ENV{'PSALM_CLONE_HANDLERS'} : 1);

# merge ignored dirs with blacklist
@ignored = (@ignored, @{$gitlab->getBlacklistPaths()});

my %config = (
    level              => $ENV{'PSALM_LEVEL'} || 4,
    paths              => $gitlab->getPaths(),
    ignoredDirectories => \@ignored,
    baseline           => $ENV{'PSALM_BASELINE'},
    baselineCheck      => $ENV{'PSALM_BASELINE_CHECK'},
    cacheDir           => $ENV{'PSALM_CACHE_DIR'},
    plugins            => \@plugins,
);

my $psalm = GPH::Psalm->new(%config);

if ($clone eq 1) {
    my @blacklist = split /,/, ($ENV{'PSALM_EXCLUDE_HANDLERS'} || '');

    print $psalm->getConfigWithIssueHandlers('./psalm.xml', @blacklist);
}
else {
    print $psalm->getConfig();
}
