## PHPMD

use `codeowner2phpmd.pl` this script generates a phpmd config which currently only is configurable to check for cyclomatic complexity.

### codeowner2phpmd variables

the following environment variable is used by the codeowner2phpmd script
- `CYCLO_LEVEL`: cyclomatic complexity threshold. defaults to 10

### example config

> gitlab-ci-yml
> ```yaml
> php-mess-detection:
>   stage: quality
>   rules:
>     - <your code owner run conditions>
>   variables:
>     DEV_TEAM: '@team-awesome'
>     EXCLUDE_PATHS: '/old,/legacy'
>     CYCLO_LEVEL: 6
>     artifacts:
>       reports:
>         codequality: phpmd-report.json
>   before_script:
>       - git fetch --depth=1 origin $CI_MERGE_REQUEST_TARGET_BRANCH_NAME
>       - export PHPMD_FILTER=$(git diff origin/$CI_MERGE_REQUEST_TARGET_BRANCH_NAME..$CI_COMMIT_SHA --diff-filter=AM --name-only -- '***.php' | .tdin2codeowner-filter.pl)
>       - .codeowner2phpmd.pl > phpmd-ruleset-ci.xml
>   script:
>     - ./vendor/bin/phpmd $PHPMD_FILTER gitlab phpmd-ruleset-ci.xml | tee phpmd-report.json
> ```
