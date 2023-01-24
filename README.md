# gitlab-perl-helpers
collection of perl helpers for implementing code owner specific gitlab ci steps

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
> phpunit-coverage:
>   stage: test
>   only:
>       - <your code owner run conditions>
>   variables:
>     DEV_TEAM: '@team-awesome'
>     MIN_COVERAGE: '80.00'
>   coverage: '/^\s*Lines:\s*\d+.\d+\%/'
>   artifacts:
>     when: always
>     reports:
>       junit: junit.xml
>       coverage_report:
>         coverage_format: cobertura
>         path: cobertura.xml
>   before_script:
>     - composer install --optimize-autoloader
>   script:
>     - .vendor/bin/phpunit --testsuite=unit --coverage-cobertura=cobertura.xml --log-junit=junit.xml --coverage-xml=coverage-xml --coverage-text --colors=never | coverage2codeowner.pl
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
>   only:
>     - <your code owner run conditions>
>   depends:
>     - phpunit-coverage
>   variables:
>     DEV_TEAM: '@team-awesome'
>     MIN_COVERED_MSI: '98.00'
>     MIN_MSI: '95.00'
>   before_script:
>     - export INFECTION_FILTER=$(codeowner2infection-filter.pl)
>   script:
>     - ./vendor/bin/infection -j$(nproc) --filter=$INFECTION_FILTER --min-msi=$MIN_MSI --min-covered-msi=$MIN_COVERED_MSI --coverage=coverage=./ --skip-initial-tests
> ```