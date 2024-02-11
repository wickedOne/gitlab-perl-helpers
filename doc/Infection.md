## Infection
several ways to interact with infection, here are some...

## codeowner2commaseparatedlist-filter

this script collects the paths defined in your CODEOWNERS file for given codeowner and outputs them to a value which can be used as for example a filter value for php infection.

### assumptions

this script assumes the presence of the CODEOWNERS file in the root directory of you project.
though configurable in the `codeowner2commaseparatedlist.pl` file, for now no plans to make that configurable or accept it as input parameter.

> [!CAUTION]    
> the `codeowner2commaseparatedlist.pl` script requires either an optimised or an authoritative classmap file so make sure to generate one of those in your configuration (see example below).

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
>     - export INFECTION_FILTER=$(codeowner2commaseparatedlist.pl)
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
