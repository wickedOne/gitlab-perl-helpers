<?php declare(strict_types = 1);
return [
    'lastFullAnalysisTime' => 1714381667,
    'meta' => array(),
    'projectExtensionFiles' => array(),
    'errorsCallback' => array(),
    'collectedDataCallback' => array(),
    'dependencies' => array(
        '/builds/phrase-tag-bundle/src/Foo/Bar.php' =>
            array (
                'fileHash' => '2530220185e341a0cbca2f061d261d1630e67c20',
                'dependentFiles' =>
                    array (
                        0 => '/builds/phrase-tag-bundle/src/Foo/Baz.php',
                    ),
            ),
        '/builds/phrase-tag-bundle/src/Foo/Baz.php' =>
            array (
                'fileHash' => '2530220185e341a0cbca2f061d261d1630e67c20',
                'dependentFiles' =>
                    array (
                        0 => '/builds/phrase-tag-bundle/src/Foo/Qux.php',
                        1 => '/builds/phrase-tag-bundle/src/Foo/Corge.php',
                    ),
            ),
        '/builds/phrase-tag-bundle/src/Foo/Qux.php' =>
            array (
                'fileHash' => '2530220185e341a0cbca2f061d261d1630e67c20',
                'dependentFiles' =>
                    array (),
            ),
        '/builds/phrase-tag-bundle/src/Foo/Corge.php' =>
            array (
                'fileHash' => '2530220185e341a0cbca2f061d261d1630e67c20',
                'dependentFiles' =>
                    array (),
            ),
    ),
    'exportedNodesCallback' => array(),
];