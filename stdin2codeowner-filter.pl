#!/usr/bin/perl -w
use strict;
use warnings FATAL => 'all';

use File::Basename;
use lib dirname(__FILE__) . '/lib/';

use GPH::Gitlab;

my $owner = $ENV{'DEV_TEAM'} or die "please define owner in DEV_TEAM env var";
my @excludes = split /,/, ($ENV{'EXCLUDE_PATHS'} || '');
my %config = (
    owner      => $owner,
    codeowners => './CODEOWNERS',
    excludes   => @excludes
);

my $gitlab = GPH::Gitlab->new(%config);

print $gitlab->intersectCommaSeparatedPathList(<STDIN>);