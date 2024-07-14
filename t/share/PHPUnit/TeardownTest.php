<?php

declare(strict_types=1);

namespace Foo\Bar;

/**
 * @author wicliff <wicliff.wolda@gmail.com>
 */
class TeardownTest extends TestCase
{
    private ?int $foo = null;
    private array $history = ['Foo', 'Bar'];
    private string $bar = 'qux';
    // comment
    private array $fixtures = [];
    private Configuration $config;
    public static ?FooProvider $fooProvider;
    public static BarProvider $barProvider;
    private ?EntityManagerInterface $entityManager = null;

    public function tearDown(): void
    {
        if ($this->entityManager->getConnection()->isTransactionActive()) {
            $this->entityManager->rollback();
        }

        unset($this->foo, $this->fixtures);

        $this->config->reset();
    }

    public function testFooBar(): void
    {
    }

    protected static function tearDownAfterClass(): void
    {
        self::$barProvider->reset();
        self::$fooProvider = null;
    }

    private Processor $processor;
}
