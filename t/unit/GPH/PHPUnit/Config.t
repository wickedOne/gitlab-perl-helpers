#!/usr/bin/perl
package t::unit::GPH::PHPUnit::Config;

use strict;
use warnings;

use Test2::V0 -target => 'GPH::PHPUnit::Config';
use Test2::Tools::Spec;

use Data::Dumper;

describe "class `$CLASS`" => sub {
    tests 'it can be instantiated' => sub {
        can_ok($CLASS, 'new');
    };

    tests 'instantiation with wrong config' => sub {
        my ($config, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $config = $CLASS->new((attributes => []))->getConfig();
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $config, '<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="phpunit.xsd"/>
', 'object as expected'
        ) or diag Dumper($config);
    };

    tests 'instantiation without config' => sub {
        my ($config, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $config = $CLASS->new()->getConfig();
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $config, '<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="phpunit.xsd"/>
', 'object as expected'
        ) or diag Dumper($config);
    };

    tests 'instantiation with config' => sub {
        my ($config, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $config = $CLASS->new((attributes => { 'bootstrap' => 'tests/bootstrap.php' }))->getConfig();
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $config, '<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" bootstrap="tests/bootstrap.php" xsi:noNamespaceSchemaLocation="phpunit.xsd"/>
', 'object as expected'
        ) or diag Dumper($config);
    };

    tests 'instantiation with config override' => sub {
        my ($config, $exception, $warnings);

        $exception = dies {
            $warnings = warns {
                $config = $CLASS->new((attributes => { 'xsi:noNamespaceSchemaLocation' => 'https://schema.phpunit.de/10.5/phpunit.xsd' }))->getConfig();
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $config, '<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="https://schema.phpunit.de/10.5/phpunit.xsd"/>
', 'object as expected'
        ) or diag Dumper($config);
    };
};

describe "class `$CLASS` php method" => sub {
    tests 'php method without config' => sub {
        my ($config, $exception, $warnings);
        my $result = '<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="phpunit.xsd"/>
';

        $exception = dies {
            $warnings = warns {
                $config = $CLASS->new()->php()->getConfig();
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $config, $result, 'object as expected'
        ) or diag Dumper($config . "\n\n\n" . $result);
    };

    tests 'php method with config' => sub {
        my ($config, $exception, $warnings);
        my $result = '<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="phpunit.xsd">
  <php>
    <server name="SHELL_VERBOSITY" value="-1"/>
  </php>
</phpunit>
';

        $exception = dies {
            $warnings = warns {
                $config = $CLASS->new()->php((server => [{ name => 'SHELL_VERBOSITY', value => '-1' }]))->getConfig();
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $config, $result, 'object as expected'
        ) or diag Dumper($config . "\n\n\n" . $result);
    };
};

describe "class `$CLASS` testsuites method" => sub {
    tests 'testsuites method without config' => sub {
        my ($config, $exception, $warnings);
        my $result = '<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="phpunit.xsd"/>
';

        $exception = dies {
            $warnings = warns {
                $config = $CLASS->new()->testsuites()->getConfig();
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $config, $result, 'object as expected'
        ) or diag Dumper($config . "\n\n\n" . $result);
    };

    tests 'testsuites method with file config' => sub {
        my ($config, $exception, $warnings);
        my %testsuites = (
            'tests.Unit' => ['tests/Unit/MapperTest.php'],
        );
        my $result = '<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="phpunit.xsd">
  <testsuites>
    <testsuite name="tests.Unit">
      <file>tests/Unit/MapperTest.php</file>
    </testsuite>
  </testsuites>
</phpunit>
';

        $exception = dies {
            $warnings = warns {
                $config = $CLASS->new()->testsuites(%testsuites)->getConfig();
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $config, $result, 'object as expected'
        ) or diag Dumper($config . "\n\n\n" . $result);
    };

    tests 'testsuites method with dir config' => sub {
        my ($config, $exception, $warnings);
        my %testsuites = (
            'tests.Functional' => [
                'tests/Functional/MapperTestCase.php',
                'tests/Functional/BarMapper',
            ],
        );
        my $result = '<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="phpunit.xsd">
  <testsuites>
    <testsuite name="tests.Functional">
      <directory>tests/Functional/BarMapper</directory>
    </testsuite>
  </testsuites>
</phpunit>
';

        $exception = dies {
            $warnings = warns {
                $config = $CLASS->new()->testsuites(%testsuites)->getConfig();
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $config, $result, 'object as expected'
        ) or diag Dumper($config . "\n\n\n" . $result);
    };
};

describe "class `$CLASS` extensions method" => sub {
    tests 'extension method without config' => sub {
        my ($config, $exception, $warnings);
        my $result = '<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="phpunit.xsd"/>
';

        $exception = dies {
            $warnings = warns {
                $config = $CLASS->new()->extensions()->getConfig();
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $config, $result, 'object as expected'
        ) or diag Dumper($config . "\n\n\n" . $result);
    };

    tests 'extension method with config' => sub {
        my ($config, $exception, $warnings);
        my $result = '<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="phpunit.xsd">
  <extensions>
    <bootstrap class="DAMA\DoctrineTestBundle\PHPUnit\PHPUnitExtension"/>
  </extensions>
</phpunit>
';

        $exception = dies {
            $warnings = warns {
                $config = $CLASS->new()->extensions(qw(DAMA\DoctrineTestBundle\PHPUnit\PHPUnitExtension))->getConfig();
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $config, $result, 'object as expected'
        ) or diag Dumper($config . "\n\n\n" . $result);
    };
};

describe "class `$CLASS` source method" => sub {
    tests 'source method without config' => sub {
        my ($config, $exception, $warnings);
        my $result = '<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="phpunit.xsd"/>
';

        $exception = dies {
            $warnings = warns {
                $config = $CLASS->new()->source()->getConfig();
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $config, $result, 'object as expected'
        ) or diag Dumper($config . "\n\n\n" . $result);
    };

    tests 'source method with directory config' => sub {
        my ($config, $exception, $warnings);
        my $result = '<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="phpunit.xsd">
  <source>
    <include>
      <directory suffix=".php">src</directory>
    </include>
  </source>
</phpunit>
';

        $exception = dies {
            $warnings = warns {
                $config = $CLASS->new()->source((
                    include => [
                        'src'
                    ],
                ))->getConfig();
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $config, $result, 'object as expected'
        ) or diag Dumper($config . "\n\n\n" . $result);
    };

tests 'source method with file config' => sub {
        my ($config, $exception, $warnings);
        my $result = '<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="phpunit.xsd">
  <source>
    <exclude>
      <file>./src/Kernel.php</file>
    </exclude>
  </source>
</phpunit>
';

        $exception = dies {
            $warnings = warns {
                $config = $CLASS->new()->source((
                    exclude => [
                        './src/Kernel.php',
                    ]
                ))->getConfig();
            };
        };

        is($exception, undef, 'no exception thrown');
        is($warnings, 0, 'no warnings generated');

        is(
            $config, $result, 'object as expected'
        ) or diag Dumper($config . "\n\n\n" . $result);
    };
};

done_testing();

