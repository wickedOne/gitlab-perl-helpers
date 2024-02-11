#!/usr/bin/perl
package t::unit::GPH::Gitlab;

use strict;
use warnings;

use Test2::V0 -target => 'GPH::Gitlab';
use Test2::Tools::Spec;

use Data::Dumper;
use Readonly;

Readonly my $CODEOWNERS_FILE => './t/share/Gitlab/CODEOWNERS';

local $SIG{__WARN__} = sub {};

describe "class `$CLASS`" => sub {
    my %config = (
        codeowners => $CODEOWNERS_FILE,
        owner =>'@teams/alpha',
        excludes => qw{.gitlab-ci.yml}
    );

    tests 'it can be instantiated' => sub {
        can_ok($CLASS, 'new');
    };

    tests "codeowners file not found" => sub {
        ok(dies{$CLASS->new((codeowners => 'foo.php', owner =>'@teams/alpha'))}, 'died with codeowners not found') or note ($@);
    };

    tests "mandatory config options" => sub {
        ok(dies{$CLASS->new((owner =>'@teams/alpha'))}, 'died with missing codeowners option') or note ($@);
        ok(dies{$CLASS->new((codeowners => $CODEOWNERS_FILE))}, 'died with missing owner option') or note ($@);
        ok(lives{$CLASS->new((owner =>'@teams/alpha', codeowners => $CODEOWNERS_FILE))}, 'lived with mandatory options') or note ($@);
    };

    tests 'owner with blacklist and exclude' => sub {
        my ($object, $exception, $warnings, @excludes);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new(%config);
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is($object->{blacklist}{'@teams/alpha'}, ['/src/Command/Config'], 'blacklist correct');
        is('.gitlab-ci.yml', not_in_set(@{$object->{codeowners}{'@teams/alpha'}}), 'excluded file not defined');
    };

    tests 'module methods' => sub {
        my ($object, $exception, $warnings, @excludes);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new(%config);
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is($object->getPaths(),
            array {
                item '/src/Command';
                item '/src/Service';
                end;
            },
            'GetPaths call correct'
        );

        is($object->getBlacklistPaths(),
            array {
                item '/src/Command/Config';
                end;
            },
            'GetBlacklistPaths call correct'
        );

        is($object->getCommaSeparatedPathList(), '/src/Command,/src/Service', 'GetCommaSeparatedPathList call correct');

        my @arr = qw|/src/Mutator/Unwrap/ /src/Command /src/Command/Config/Processor|;

        is($object->intersectCommaSeparatedPathList(@arr), '/src/Command', 'IntersectToCommaSeparatedPathList call correct');

        is([$object->intersect(@arr)],
            array {
                item '/src/Command';
                end;
            },
            'Intersect call correct'
        );

        is($object->match('/src/Service'), 1, 'Match call match correct');
        is($object->match('src/Mutator/Unwrap/'), 0, 'Match call no match correct');

        is($object->matchBlacklist('/src/Command/Config/Processor'), 1, 'MatchBlacklist call match correct');
        is($object->matchBlacklist('/src/Service/SomeService'), 0, 'MatchBlacklist call no match correct');
    };
};

done_testing();

