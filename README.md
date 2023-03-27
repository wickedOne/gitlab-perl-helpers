# gitlab-perl-helpers

collection of perl helpers for implementing code owner specific gitlab ci steps

## environment variables

these scripts rely on a couple of environment variables.

### global variables

the following environment variables are used by all scripts
- `DEV_TEAM`: owner as defined in the `CODEOWNERS` file
- `EXCLUDE_PATHS` (optional): comma seperated list of paths to exclude while defined in the `CODEOWNERS` file for owner `DEV_TEAM`. defaults to empty string.

### coverage2codeowner variables

the following environment variable is used by the coverage2codeowner script
- `MIN_COVERAGE` (optional): minimum coverage required for the job to succeed. defaults to 0.0

### codeowner2psalm variables

the following environment variable is used by the codeowner2psalm script
- `PSALM_LEVEL`: psalm error level
- `PSALM_BASELINE` (optional): path to baseline file
- `PSALM_CACHE_DIR` (optional): path to cache directory. defaults to `./psalm/`
- `PSALM_IGNORED_DIRS` (optional): comma seperated list of directories to ignore


## coverage2codeowner

filters and re-calculates phpunit's coverage text output for a specific codeowner based on the paths defined in gitlab's CODEOWNER file.

on top of that a minimum coverage percentage can be defined (defaults to 0.0) which will cause your pipeline to fail if the line coverage % dives below that threshold.

### assumptions

this script assumes the presence of composer at the usual location and the CODEOWNERS file in the root directory of you project.
though both paths are configurable in the `coverage2codeowner.pl` file, for now no plans to make that configurable or accept them as input parameters.

**note:** the script _does not_ alter how your test suite runs in any way (so no run filters are applied), it just filters the output and re-calculates the summary.
this way the other coverage artifacts (junit & xml) can be used by for example infection (see below)

### example config

> gitlab-ci.yml
> ```yaml
>  codeowners-phpunit-coverage:
>    stage: test
>    needs:
>      - composer-install
>    variables:
>      MIN_COVERAGE: '85.00'
>      DEV_TEAM: '@team-awesome'
>      EXCLUDE_PATHS: 'legacy/'
>    artifacts:
>      expire_in: 1 hour
>      when: always
>      paths:
>        - var/log/phpunit/*
>      reports:
>        junit: var/log/phpunit/junit.xml
>        coverage_report:
>          coverage_format: cobertura
>          path: var/log/phpunit/cobertura.xml
>    coverage: '/^\s*Lines:\s*\d+.\d+\%/'
>    rules:
>      - <your code owners run conditions>
>    before_script:
>      - composer dump-autoload --optimize --ignore-platform-reqs
>    script:
>      - php -dextension=pcov.so -dpcov.enabled=1 -dpcov.directory=src/ ./vendor/bin/phpunit --testsuite=unit --coverage-xml=var/log/phpunit/coverage-xml --log-junit=var/log/phpunit/junit.xml --coverage-cobertura=var/log/phpunit/cobertura.xml --exclude-group=isolated --coverage-text --colors=never | ./.codeowners/coverage2codeowner.pl
> ```

## codeowner2infection-filter

this script collects the paths defined in your CODEOWNERS file for given codeowner and outputs them to a value which can be used as for example a filter value for php infection.

### assumptions

this script assumes the presence of the CODEOWNERS file in the root directory of you project.
though configurable in the `codeowner2infection-filter.pl` file, for now no plans to make that configurable or accept it as input parameter.

### example config

> gitlab-ci-yml
> ```yaml
> php-infection:
>   stage: test
>   rules:
>     - <your code owner run conditions>
>   needs:
>     - phpunit-coverage
>   variables:
>     DEV_TEAM: '@team-awesome'
>     EXCLUDE_PATHS: '/old,/legacy'
>     MIN_COVERED_MSI: '98.00'
>     MIN_MSI: '95.00'
>   before_script:
>     - composer dump-autoload --optimize --ignore-platform-reqs
>     - export INFECTION_FILTER=$(codeowner2infection-filter.pl)
>   script:
>     - ./vendor/bin/infection -j$(nproc) --filter=$INFECTION_FILTER --min-msi=$MIN_MSI --min-covered-msi=$MIN_COVERED_MSI --coverage=./coverage --skip-initial-tests
> ```

## stdin2codeowner-filter.pl

this script accepts a list of files and intersects them with the paths defined in your CODEOWNERS file for given codeowner. the intersected result is printed as comma separated list which can be used as a filter value for, for example, php infection.

### assumptions

this script assumes the presence of the CODEOWNERS file in the root directory of you project.
though configurable in the `stdin2codeowner-filter.pl` file, for now no plans to make that configurable or accept it as input parameter.

### example config

> gitlab-ci-yml
> ```yaml
> php-infection:
>   stage: test
>   rules:
>     - <your code owner run conditions>
>   needs:
>     - phpunit-coverage
>   variables:
>     DEV_TEAM: '@team-awesome'
>     EXCLUDE_PATHS: '/old,/legacy'
>     MIN_COVERED_MSI: '98.00'
>     MIN_MSI: '95.00'
>   before_script:
>     - composer dump-autoload --optimize --ignore-platform-reqs
>     - git fetch --depth=1 origin $CI_MERGE_REQUEST_TARGET_BRANCH_NAME
>     - export INFECTION_FILTER=$(git diff origin/$CI_MERGE_REQUEST_TARGET_BRANCH_NAME --diff-filter=AM --name-only | .stdin2codeowner-filter.pl)
>   script:
>     - ./vendor/bin/infection -j$(nproc) --filter=$INFECTION_FILTER --min-msi=$MIN_MSI --min-covered-msi=$MIN_COVERED_MSI --coverage=./coverage --skip-initial-tests
> ```
 
## infection2escapee-warning

this script parses infection output and returns an alternative exit code (8) when the (covered) MSI is within the given boundaries, but does contain undetected mutants.
combined with gitlab's [allow_failure:exit_codes](https://docs.gitlab.com/ee/ci/yaml/#allow_failureexit_codes) feature you can configure your ci job to raise a warning while not blocking the merge request from being merged.

### assumptions
this script assumes both `MIN_MSI` and `MIN_COVERED_MSI` are configured.

### example config

> gitlab-ci-yml
> ```yaml
> php-infection:
>   stage: test
>   rules:
>     - <your code owner run conditions>
>   variables:
>     MIN_COVERED_MSI: '98.00'
>     MIN_MSI: '95.00'
>   allow_failure:
>     exit_codes: 8
>   script:
>     - set +e
>     - ./vendor/bin/infection | infection2escapee-warning.pl
> ```

## codeowner2psalm

this script generates a psalm config based on the paths defined in your `CODEOWNERS` file.

### assumptions

this script assumes the presence of the CODEOWNERS file in the root directory of you project.

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
