#!/usr/bin/perl
package t::unit::GPH::Composer;

use warnings;

use Test2::V0 -target => 'GPH::Composer';
use Test2::Tools::Spec;
use Data::Dumper;

use constant CLASSMAP_FILE => './t/share/Composer/autoload_classmap.php';

local $SIG{__WARN__} = sub {
    # warn $_[0] unless ($_[0] =~ /^Module::Pluggable will be removed/);
};

describe "class `$CLASS`" => sub {
    tests 'it can be instantiated' => sub {
        can_ok($CLASS, 'new');
    };

    tests 'classmap instantiation' => sub {
        my ($object, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $object = $CLASS->new(CLASSMAP_FILE);
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        isnt($object->{classmap}, undef, 'classmap has been set');
        ref_ok($object->getClassMap());
    }
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
                $object = $CLASS->new(CLASSMAP_FILE);
                $result = $object->match($className, @paths);
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');
        is($result, $match, 'expected code returned');
    };
};

done_testing();

