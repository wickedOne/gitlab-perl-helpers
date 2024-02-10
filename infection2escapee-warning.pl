#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

use File::Basename;
use lib dirname(__FILE__) . '/lib/';

use GPH::Infection;

my $infection = GPH::Infection->new($ENV{'MIN_MSI'}, $ENV{'MIN_COVERED_MSI'}, 8);

exit $infection->Parse();