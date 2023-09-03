## PHPUnit

`coverage2codeowner.pl` filters and re-calculates phpunit's coverage text output for a specific codeowner based on the paths defined in gitlab's CODEOWNER file.

on top of that a minimum coverage percentage can be defined (defaults to 0.1) which will cause your pipeline to fail if the line coverage % dives below that threshold.

### global variables

the following environment variables are used by all scripts
- `DEV_TEAM`: owner as defined in the `CODEOWNERS` file
- `EXCLUDE_PATHS`: (optional): comma seperated list of paths to exclude while defined in the `CODEOWNERS` file for owner `DEV_TEAM`. defaults to empty string.

### variables

the following environment variable is used by the coverage2codeowner script
- `MIN_COVERAGE` (optional): minimum coverage required for the job to succeed. defaults to 0.1

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