#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

use File::Basename;
use lib dirname(__FILE__) . '/lib/';

use GPH::Infection;

my $infection = GPH::Infection->new((msi => $ENV{'MIN_MSI'}, covered => $ENV{'MIN_COVERED_MSI'}));

exit $infection->parse();