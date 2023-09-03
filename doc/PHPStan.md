## PHPStan

the `codeowner2phpstan.pl` script generated a phpstan config file based on the paths defined in your `CODEOWNERS` file.

### variables

the following environment variables are used by the codeowner2phpstan script
- `PHPSTAN_LEVEL`: (optional) phpstan level to use (defaults to `6`)
- `PHPSTAN_BASELINE`: (optional) path to baseline file
- `PHPSTAN_CACHE_DIR`: (optional) cache directory used (defaults to `var`)
- `PHPSTAN_IGNORED_DIRS`: (optional) directories to ignore
- `PHPSTAN_INCLUDES`: (optional) comma seperated list of files to include
- `PHPSTAN_THREADS`: (optional) number of threads to use (defaults to `4`)
- 
### assumptions

this script assumes the presence of the CODEOWNERS file in the root directory of you project.

### example config

> gitlab-ci-yml
> ```yaml
> phpstan:
>   stage: quality
>   rules:
>     - <your code owner run conditions>
>   variables:
>     DEV_TEAM: '@team-awesome'
>     EXCLUDE_PATHS: '/old,/legacy'
>     PHPSTAN_LEVEL: max
>     artifacts:
>       - ./phpstan-ci.neon
>   before_script:
>       - ./codeowner2phpstan.pl > phpstan-ci.neon
>   script:
>     - ./vendor/bin/phpstan analyse --config=phpstan-ci.neon --threads=4
> ```
