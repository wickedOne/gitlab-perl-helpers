<?php

trigger_error(sprintf('%s should not be used, use %s instead', Foo::class, Bar::class));

final readonly class Foo
{

}