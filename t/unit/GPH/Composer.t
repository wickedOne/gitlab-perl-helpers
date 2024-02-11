#!/usr/bin/perl
package t::unit::GPH::Composer;

use strict;
use warnings;

use Test2::V0 -target => 'GPH::Composer';
use Test2::Tools::Spec;

use Data::Dumper;
use Readonly;

local $SIG{__WARN__} = sub {};

Readonly my $CLASSMAP_FILE => './t/share/Composer/autoload_classmap.php';

describe "class `$CLASS`" => sub {
    tests 'it can be instantiated' => sub {
        can_ok($CLASS, 'new');
    };

    tests 'classmap instantiation' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((classmap => $CLASSMAP_FILE));
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        isnt($object->{classmap}, undef, 'classmap has been set');
        ref_ok($object->getClassMap());
    };

    tests "classmap not found" => sub {
        ok(dies{$CLASS->new((classmap => 'foo.php'))}, 'died with classmap not found') or note ($@);
    };

    tests "mandatory config options" => sub {
        ok(dies{$CLASS->new(())}, 'died with missing classmap option') or note ($@);
        ok(lives{$CLASS->new((classmap => $CLASSMAP_FILE))}, 'lived with mandatory options') or note ($@);
    };
};

describe 'test matching' => sub {
    my @paths = qw(|src/Service/PhraseTagService.php src/Command/AbstractPhraseKeyCommand.php|);
    my ($className, $match);

    case 'matching class' => sub {
        $className = 'WickedOne\PhraseTagBundle\Command\AbstractPhraseKeyCommand';
        $match = 1;
    };

    case 'non matching class: different vendor class' => sub {
        $className = 'Infection\Event\Subscriber\EventSubscriber';
        $match = 0;
    };

    case 'non matching class: untrimmed' => sub {
        $className = '    WickedOne\PhraseTagBundle\Command\AbstractPhraseKeyCommand';
        $match = 0;
    };

    case 'non matching class: missing vendor name' => sub {
        $className = 'PhraseTagBundle\Service\PhraseTagService';
        $match = 0;
    };

    tests 'match' => sub {
        my ( $object, $exception, $warnings, $result );

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new((classmap => $CLASSMAP_FILE));
                $result = $object->match($className, @paths);
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');
        is($result, $match, 'expected code returned');
    };
};

done_testing();

