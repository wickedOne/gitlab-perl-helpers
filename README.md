# gitlab-perl-helpers

collection of perl helpers for implementing code owner specific gitlab ci steps.
the general idea is to use the paths defined in the `CODEOWNERS` file for your team to interact with the merge request by either using all paths in the `CODEOWNERS` file, or intersect the merge request changes with those.

## environment variables

these scripts rely on a couple of environment variables.

### global variables

the following environment variables are used by all scripts
- `DEV_TEAM`: owner as defined in the `CODEOWNERS` file
- `EXCLUDE_PATHS`: (optional): comma seperated list of paths to exclude while defined in the `CODEOWNERS` file for owner `DEV_TEAM`. defaults to empty string.

## details

most scripts generate a custom config file on the fly.

for more details on supported (static) analysis tools and implementation examples see the following:
1. [PHPUNIT](doc/PHPUnit.md)
2. [Infection](doc/Infection.md)
3. [Psalm](doc/Psalm.md)
4. [PHPStan](doc/PHPStan.md)
5. [PHPMD](doc/PHPMD.md)