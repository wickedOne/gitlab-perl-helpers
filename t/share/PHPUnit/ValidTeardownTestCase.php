<?php

declare(strict_types=1);

namespace Foo\Bar;

/**
 * @author wicliff <wicliff.wolda@gmail.com>
 */
class ValidTeardownTestCase extends TestCase
{
    private ?int $foo = null;
    private static array $fixtures = [];

    public function tearDown(): void
    {
        unset($this->foo);
    }

    public function testFooBar(): void
    {
    }

    protected static function tearDownAfterClass(): void
    {
        self::$fixtures = [];
    }
}
