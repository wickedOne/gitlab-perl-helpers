#!/usr/bin/perl -w
use strict;
use warnings FATAL => 'all';

use File::Basename;
use lib dirname(__FILE__) . '/lib/';

use Gitlab;
use PHPStan;

use constant CODEOWNERS_FILE => './CODEOWNERS';

my $owner  = $ENV{'DEV_TEAM'} or die "please define owner in DEV_TEAM env var";

my $exclude = $ENV{'EXCLUDE_PATHS'} || '';
my @excludes = split /,/, $exclude;

my $level = $ENV{'PHPSTAN_LEVEL'} || 6;
my $baseline = $ENV{'PHPSTAN_BASELINE'} || undef;
my $cacheDir = $ENV{'PHPSTAN_CACHE_DIR'} || undef;
my $ignore = $ENV{'PHPSTAN_IGNORED_DIRS'} || '';
my @ignored = split /,/, $ignore;
my $includes = $ENV{'PHPSTAN_INCLUDES'} || './phpstan.ci.neon';
my @includes = split /,/, $includes;
my $threads = $ENV{'PHPSTAN_THREADS'} || undef;

my $gitlab = Gitlab->new(CODEOWNERS_FILE, $owner, @excludes);

# merge ignored dirs with blacklist
@ignored = (@ignored, $gitlab->GetBlacklistPaths());

my $phpstan = PHPStan->new($level, $gitlab->GetPathsReference(), $baseline, \@ignored, $cacheDir, \@includes, $threads);

print $phpstan->GetConfig();
