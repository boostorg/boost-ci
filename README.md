![Boost](images/boost.png  "Boost")

# Boost.CI

This repository contains scripts that enable continuous integration (CI) with
[Appveyor](https://www.appveyor.com/),
[Azure Pipelines](https://github.com/marketplace/azure-pipelines),
[codecov.io](https://codecov.io/),
[Coverity Scan](https://scan.coverity.com/),
[GitHub Actions](https://github.com/features/actions),
[Drone](https://drone.io/),
and [Travis CI](https://travis-ci.com/).
These scripts are intended to be downloaded and used during boost repository builds to improve project quality.
In most cases the scripts are self-configuring.
Some integrations require additional setup actions to complete.

Boost.CI also allows you to run a big-endian build on Github Actions.

### Build Status

<!-- boost-ci/tools/makebadges.sh --repo boost-ci --appveyorbadge ynnd2l3gu4oiyium --appveyororg Flamefire --codecovbadge mncfhR5Zjv -p -d -n -->
| Branch          | GHA CI | Appveyor | Azure Pipelines | Drone | codecov.io |
| :-------------: | ------ | -------- | --------------- | ----- | ---------- |
| [`master`](https://github.com/boostorg/boost-ci/tree/master) | [![Build Status](https://github.com/boostorg/boost-ci/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/boostorg/boost-ci/actions?query=branch:master) | [![Build status](https://ci.appveyor.com/api/projects/status/ynnd2l3gu4oiyium/branch/master?svg=true)](https://ci.appveyor.com/project/Flamefire/boost-ci/branch/master) | [![Build Status](https://dev.azure.com/boostorg/boost-ci/_apis/build/status/boostorg.boost-ci?branchName=master)](https://dev.azure.com/boostorg/boost-ci/_build/latest?definitionId=8&branchName=master) | [![Build Status](https://drone.cpp.al/api/badges/boostorg/boost-ci/status.svg?ref=refs/heads/master)](https://drone.cpp.al/boostorg/boost-ci) | [![codecov](https://codecov.io/gh/boostorg/boost-ci/branch/master/graph/badge.svg?token=mncfhR5Zjv)](https://codecov.io/gh/boostorg/boost-ci/tree/master) |

## Summary (TL;DR)

Here are all the steps you need to take as a Boost repository maintainer to enable all of these CI features in your repository.
(Note that you may skip some steps, e.g. if you don't need a specific CI service):

1. Checkout `develop` and then make a new branch called `ci`.
1. Copy the `.appveyor.yml` file from this repository into the *top level* of your repository.
1. Copy the `.azure-pipelines.yml` file from this repository into the top level of your repository.
1. Copy the `.travis.yml` file from this repository into the top level of your repository.
1. Copy the `.github/workflows/ci.yml` file from this repository into the the same folder in your repository.
    * Note that those include CMake tests, so see the [CMake docs](CMake.md#ci-tests) for details and requirements.
    * For some features to work the `B2_CI_VERSION` variable set in those configs is relevant as without that a legacy codepath will be used to ensure compatibility with old CI configs if that is unset or set to zero.
1. Copy the `.drone.star` file and optionally the `.drone` directory from this repository to the top level of your repository.
1. Copy the `.codecov.yml` file from this repository to the top level of your repository and edit if required. Note that **only** the file in the default branch (usually `master`/`main`, or `develop` for most Boost libraries) is considered!
1. Copy the `LICENSE` file from this repository to the top level of your repository.  This adds the `BSL-1.0` designation to your repository on github.
1. [optional] Copy the `README.template.md` file from this repository to the top level `README.md` of your repository.  If you already have a README.md then you can take what you need from the template version to improve it, if desired.  Otherwise, you will need to customize README.md for your repository.  One useful step is to fixup the repository name using the command `sed -i 's/template/<myrepositoryname>/g' README.md`, and then update the first line description.
1. In Appveyor, add a project for your fork of the repository.  No customization is needed.
1. In Travis CI, add a project for your fork of the repository.  Later you will customize it for Coverity Scan, but for now no settings changes are necessary.
1. Commit these changes and push to your personal fork in the ci branch.
1. Create a pull request in your fork of <myrepositoryname>/ci to <myrepositoryname>/develop.  Do not target boostorg/develop.
1. Observe that the CI services are running the build jobs.  Fix up any issues found.  Note this may uncover defects in your repository code.
1. If you are the owner or an admin for your repository, add projects in Appveyor and Travis CI for the boostorg/<myrepositoryname> project (not your fork).  If you are just a contributor in the repository, create an [issue in Boost.Admin](https://github.com/boostorg/admin/issues) requesting Appveyor and Travis CI to be enabled for the repository.
1. Commit the changes to develop.  This will kick off a build.
1. Update the badge matrix in README.md with the correct links for your CI projects in use (e.g. Appveyor, Github Actions, Drone).
1. Create a Coverity Scan account if you have not already done so.
1. Create a new Coverity Scan github based project for your official boostorg repository.
1. In the CI settings (Github Actions, Drone and/or Travis) for your boostorg repository project add the following as **secrets**:
    * `CODECOV_TOKEN` is the "Repository Upload Token" from the project settings on [Codecov](https://codecov.io).
    * `COVERITY_SCAN_NOTIFICATION_EMAIL` is your email account (doesn't need to be a secret, but can be an environment variable for the repo).
    * `COVERITY_SCAN_TOKEN` is the scan token you can find in the project settings in Coverity Scan.
    * For GHA this is "Settings" -> "Secrets and Variables" -> "Actions" -> "Repository secrets"
    * In Drone it is "Settings" -> "Secrets" (**Different names:** `coverity_scan_email`, `coverity_scan_token`)
1. Update the README.md to put the correct Coverity Scan badge project number into the badge URLs.
1. This will kick off a build on the develop branch that will include Coverity Scan results.
1. To activate Drone, visit https://drone.cpp.al. Authorize Drone: Click the "Authorize cppalliance-drone" button. Sync repositories: Click the "sync" button. A list of repositories will appear. For the relevant repo, click and then choose "Activate Repository". In the settings page, change Configuration from .drone.yml to .drone.star. "Save".
1. More pointers about Drone:
    * Ensure that shell scripts are executable: `chmod 755 .drone/drone.sh`
    * The install-script (in `ci/drone`) and run-script (in `.drone`) for the Unix-ish jobs will be downloaded from Boost.CI if they don't exist, so you only need them when you want to customize the build.
    * The `.drone/{before,after}-install.*` scripts are sourced around the common_install step (which e.g. bootstraps B2) of the [default build](.drone/drone.sh), if they exist. So you can remove them when not required.
    * "asan" jobs require elevated privileges. Contact an administrator or open an issue at [drone-ci](https://github.com/CPPAlliance/drone-ci) to set your drone repository to "Trusted".
    * If not using asan, simply remove the jobs.
    * **Codecov:** Copy the "Repository Upload Token" from the settings page of your repo on [Codecov](https://codecov.io) to a secret named `codecov_token` on the settings page of your repo on [Drone](https://drone.cpp.al).
    * **Coverity:** Copy the token from the repos settings page on [Coverity](https://scan.coverity.com/) and an E-Mail-Address to a secrets named `coverity_scan_token` and `coverity_scan_email` respectively on the settings page of your repo on [Drone](https://drone.cpp.al).
    * If you need a package installed on MacOS or FreeBSD, by the root user, please open an issue.
    * Further info available at https://github.com/CPPAlliance/drone-ci

## Code coverage

Multiple CI configs contain jobs collecting code coverage data.
E.g. Github Actions and Drone CI for Linux and Appveyor for Windows.
Especially the latter allows to collect coverage data for Windows-only codeparts or code using e.g. `wchar_t` which is different on Windows than on other platforms.

### Exclusion of coverage data

If you want to exclude parts of your code from coverage analysis you can use the LCOV comments/macros:

- `// LCOV_EXCL_LINE` for a single line
- `// LCOV_EXCL_START` and `// LCOV_EXCL_STOP` for a range of code

See the LCov manual for more information.

To exclude whole files or folders you can use the `ignore`-object and glob patterns in in the `.codecov.yml` file.
See the example file in the root of this repository for a starting point.   
**Important**: Codecov only considers the configuration file of the *default* branch (usually: `master`), **not** the one in the current build/PR branch.
See the [CodeCov documentation](https://docs.codecov.com/docs/codecov-yaml) for details.

## Repositories using Boost.CI

The [CMT Stale Repo Tracker](https://github.com/jeking3/boost-merge-reminder/actions) identifies many repositories using Boost.CI and
the [CMT Status Spreadsheet](https://docs.google.com/spreadsheets/d/1aFdTMdJmmD9L5IyvJx-nj3BrMVztmlNo8QwyEzLD2io/edit?usp=sharing) shows the current state of each.
There may be additional repositories using Boost.CI that are not listed.  Boost.CI does not track usage internally.

## How It Works

The CI config files (such as `.appveyor.yml`, `.azure-pipeline.yml` and `.github/workflows/ci.yml`) must exist in your repository and will contain your customizations for build types, languages, and platforms.
The templates provided will get you started with the build jobs listed below.

These scripts will copy resources from the Boost.CI repository when needed in order to provide scripting necessary to run all these jobs successfully.

Build jobs that will severely impact performance (such as `valgrind`) will define `BOOST_NO_STRESS_TEST` so those can be skipped or hobbled.

## Topic Branch Support

The configuration for Github Actions, Azure Pipelines, Appveyor and Travis CI allow for automated branch builds on branch pushes matching these names:

- master
- develop
- bugfix/*
- feature/*
- fix/*
- pr/*

Note that when opening a Pull Request (PR) the use of a topic branch name is not required and even discouraged as PRs are always built on CI and the use of a topic branch name will lead to duplicating all builds.

A good strategy is to only use a topic branch name when actively working on a changeset and when you want CI to run for each push of that branch.
When the changeset is (mostly) done it is advised to rename the branch right before opening a PR to avoid that double-build issue.
This can be done easily via the GitHub website (check the "branches" link at the repo overview page) or of course via command line (push to a new remote branch and delete the old one).

## Defaults, Builds and Services

By default the builds target multiple different C++ versions (from C++98 to C++23), and this can be customized.
To see what kind of coverage these builds provide, see some build results as follows or click the badges above:

- AppVeyor : https://ci.appveyor.com/project/Flamefire/boost-ci/branch/master
- Github Actions : https://github.com/boostorg/boost-ci/actions/workflows/ci.yml
- Azure Pipelines : https://dev.azure.com/boostorg/boost-ci/_build/latest?definitionId=8&branchName=master
