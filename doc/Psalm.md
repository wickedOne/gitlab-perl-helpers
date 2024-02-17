## Psalm

`codeowner2psalm.pl` script generates a psalm config based on the paths defined in your `CODEOWNERS` file.

### variables

the following environment variables are used by the codeowner2psalm script
- `PSALM_LEVEL`: psalm error level
- `PSALM_BASELINE`: (optional): path to baseline file
- `PSALM_BASELINE_CHECK`: (optional): `true` or `false` enable baseline check. defaults to `true` when `PSALM_BASELINE` is set.
- `PSALM_CACHE_DIR`: (optional): path to cache directory. defaults to `./psalm/`
- `PSALM_IGNORED_DIRS`: (optional): comma seperated list of directories to ignore
- `PSALM_CLONE_HANDLERS`: (optional): clone issue handlers node from given psalm config. defaults to true
- `PSALM_EXCLUDE_HANDLERS`: (optional): only when `PSALM_CLONE_HANDLERS` is enabled. comma seperated list of handler names which to exclude from the cloning operation. defaults to empty list.

### example config

> gitlab-ci-yml
> ```yaml
> codeowner-psalm:
>   stage: quality
>   rules:
>     - <your code owner run conditions>
>   needs:
>     - composer-install
>   variables:
>     DEV_TEAM: '@team-awesome'
>     EXCLUDE_PATHS: '/old,/legacy'
>     PSALM_LEVEL: '2'
>     PSALM_IGNORED_DIRS: 'src/Bridge'
>   before_script:
>     - codeowner2psalm.pl > psalm-ci.xml
>   script:
>     - ./vendor/bin/psalm -c psalm-ci.xml
> ```