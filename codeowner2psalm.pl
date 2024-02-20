#!/usr/bin/perl -w
use strict;
use warnings FATAL => 'all';

use File::Basename;
use lib dirname(__FILE__) . '/lib/';

use GPH::Gitlab;
use GPH::Psalm;

my $owner = $ENV{'DEV_TEAM'} or die "please define owner in DEV_TEAM env var";
my @excludes = split /,/, ($ENV{'EXCLUDE_PATHS'} || '');
my $codeonwers = $ENV{'CODEOWNERS'} || './CODEOWNERS';

my %gitlabConfig = (
    owner      => $owner,
    codeowners => $codeonwers,
    excludes   => \@excludes,
);

my $gitlab = GPH::Gitlab->new(%gitlabConfig);

my @ignored = split /,/, ($ENV{'PSALM_IGNORED_DIRS'} || '');
my @plugins = split /,/, ($ENV{'PSALM_PLUGINS'} || '');
my $clone = (defined($ENV{'PSALM_CLONE_HANDLERS'}) ? $ENV{'PSALM_CLONE_HANDLERS'} : 1);

# merge ignored dirs with blacklist
@ignored = (@ignored, @{$gitlab->getBlacklistPaths()});

my %config = (
    level               => $ENV{'PSALM_LEVEL'} || 4,
    paths               => $gitlab->getPaths(),
    ignored_directories => \@ignored,
    baseline            => $ENV{'PSALM_BASELINE'},
    baseline_check      => $ENV{'PSALM_BASELINE_CHECK'},
    cache_dir           => $ENV{'PSALM_CACHE_DIR'},
    plugins             => \@plugins,
);

my $psalm = GPH::Psalm->new(%config);

if ($clone eq 1) {
    my @blacklist = split /,/, ($ENV{'PSALM_EXCLUDE_HANDLERS'} || '');
    my $base = $ENV{'PSALM_BASE_CONFIG'} || './psalm.xml';

    print $psalm->getConfigWithIssueHandlers($base, @blacklist);
}
else {
    print $psalm->getConfig();
}
