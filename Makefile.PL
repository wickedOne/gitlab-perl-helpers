use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    ABSTRACT           => "collection of perl helpers for implementing code owner specific gitlab ci steps.",
    AUTHOR             => "wicliff wolda <wicliff.wolda\@gmail.com>",
    NAME               => 'GPH',
    VERSION_FROM       => 'lib/GPH.pm',
    LICENSE            => 'perl',
    PREREQ_PM          => {
        "File::Basename" => 0,
        "Time::Piece"    => 0,
        "XML::LibXML"    => 0
    },
    CONFIGURE_REQUIRES => {
        "ExtUtils::MakeMaker" => 0
    },
    TEST_REQUIRES      => {
        "Test2::V0"          => 0,
        "Test2::Tools::Spec" => 0,
        "Data::Dumper"       => 0,
        "Readonly"           => 0,
        "File::Temp"         => 0,
    },
    'test'             => {
        TESTS => 't/unit/GPH/*.t t/unit/GPH/*/*.t'
    }
);

