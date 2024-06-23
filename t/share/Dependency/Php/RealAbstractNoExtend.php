<?php

declare(strict_types=1);

namespace Foo;

use Foo\Mapper;
use function array_map;

// use comment;
abstract class RealAbstractNoExtend
{
    /**
     * @return void
     */
    public function foo(): void
    {
        $fixtures = [
            '../Yaml/fixtures.yml',
//            't/share/Dependency/Yaml/fixtures_commented.yml',
            '../Yaml/App/sub_fixtures.yaml'
        ];
    }
}