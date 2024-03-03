#!/usr/bin/perl -w
use strict;
use warnings FATAL => 'all';

use File::Basename;
use lib dirname(__FILE__) . '/lib/';

use GPH::Util::Php;
use GPH::Gitlab;

my $owner = $ENV{'DEV_TEAM'} or die "please define owner in DEV_TEAM env var";
my @excludes = split /,/, ($ENV{'EXCLUDE_PATHS'} || '');
my $codeonwers = $ENV{'CODEOWNERS'} || './CODEOWNERS';
my @types = split /,/, ($ENV{'PHP_EXCLUDE_TYPES'} || '');

my %config = (
    owner      => $owner,
    codeowners => $codeonwers,
    excludes   => \@excludes,
);

my $gitlab = GPH::Gitlab->new(%config);
my $util = GPH::Util::Php->new();

my @paths = $gitlab->intersect(<STDIN>);

print join(",", $util->reduce((paths => \@paths, excludes => @types)));