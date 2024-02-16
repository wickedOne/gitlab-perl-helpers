#!/usr/bin/perl -w
use strict;
use warnings FATAL => 'all';

use File::Basename;
use lib dirname(__FILE__) . '/lib/';

use GPH::Gitlab;
use GPH::PHPStan;

my $owner  = $ENV{'DEV_TEAM'} or die "please define owner in DEV_TEAM env var";
my @excludes = split /,/, ($ENV{'EXCLUDE_PATHS'} || '');

my %gitlabConfig = (
    owner      => $owner,
    codeowners => './CODEOWNERS',
    excludes   => \@excludes,
);

my $gitlab = GPH::Gitlab->new(%gitlabConfig);

my @includes = split /,/, ($ENV{'PHPSTAN_INCLUDES'} || './phpstan.ci.neon');
my @ignored = split /,/, ($ENV{'PHPSTAN_IGNORED_DIRS'} || '');

@ignored = (@ignored, $gitlab->getBlacklistPaths()); # merge ignored dirs with blacklist

my %config = (
    level              => $ENV{'PHPSTAN_LEVEL'} || 6,
    paths              => $gitlab->getPaths(),
    baseline           => $ENV{'PHPSTAN_BASELINE'},
    ignoredDirectories => @ignored,
    cacheDir           => $ENV{'PHPSTAN_CACHE_DIR'},
    includes           => \@includes,
    threads            => $ENV{'PHPSTAN_THREADS'}
);

my $phpstan = GPH::PHPStan->new(%config);

print $phpstan->getConfig();
