![Boost](images/boost.png  "Boost")

# Boost.CI #

This repository contains scripts that enable continuous integration with [Appveyor](https://www.appveyor.com/),
[Azure Pipelines](https://github.com/marketplace/azure-pipelines), [codecov.io](https://codecov.io/),
[Coverity Scan](https://scan.coverity.com/), and [Travis CI](https://travis-ci.org/).
These scripts are intended to be downloaded and used during boost repository builds to improve project quality.
In most cases the scripts are self-configuring.  Some integrations require additional setup actions to complete.

Boost.CI also allows you to run a big-endian build on Travis CI.

## Summary (TL;DR) ##

Here are all the steps you need to take as a Boost repository maintainer to enable all of these CI features in your repository:

1. Checkout `develop` and then make a new branch called `ci`.
1. Copy the `.appveyor.yml` file from this repository into the *top level* of your repository.
1. Copy the `.azure-pipelines.yml` file from this repository into the top level or your repository.
1. Copy the `.travis.yml` file from this repository into the top level or your repository.
1. Copy the `LICENSE` file from this repository to the top level of your repository.  This adds the `BSL-1.0` designation to your repository on github.
1. [optional] Copy the `templates/README.md` file from this repository to the top level of your repository.  If you already have a README.md then you can take what you need from the template version to improve it, if desired.  Otherwise, you will need to customize README.md for your repository.  One useful step is to fixup the repository name using the command `sed -i 's/template/<myrepositoryname>/g' README.md`, and then update the first line description.
1. In Appveyor, add a project for your fork of the repository.  No customization is needed.
1. In Travis CI, add a project for your fork of the repository.  Later you will customize it for Coverity Scan, but for now no settings changes are necessary.
1. Commit these changes and push to your personal fork in the ci branch.
1. Create a pull request in your fork of <myrepositoryname>/ci to <myrepositoryname>/develop.  Do not target boostorg/develop.
1. Observe that both Appveyor and Travis CI are running the build jobs.  Fix up any issues found.  Note this may uncover defects in your repository code.
1. If you are the owner or an admin for your repository, add projects in Appveyor and Travis CI for the boostorg/<myrepositoryname> project (not your fork).  If you are just a contributor in the repository, create an [issue in Boost.Admin](https://github.com/boostorg/admin/issues) requesting Appveyor and Travis CI to be enabled for the repository.
1. Commit the changes to develop.  This will kick off a build on Appveyor and Travis.
1. Update the badge matrix in README.md with the correct links for your Appveyor and Travis CI projects.
1. Create a Coverity Scan account if you have not already done so.
1. Create a new Coverity Scan github based project for your official boostorg repository.
1. Update your Travis CI boostorg repository project settings and add the following environment variables using the Travis CI GUI:
    * `COVERITY_SCAN_NOTIFICATION_EMAIL` can be public and set to your email account (or it can be private).
    * `COVERITY_SCAN_TOKEN` should be kept private and set to the scan token you can find in the project settings in Coverity Scan.
1. Update the README.md to put the correct Coverity Scan badge project number into the badge URLs.
1. This will kick off a build on the develop branch that will include Coverity Scan results.

## Repositories using Boost.CI ###

The [CMT Stale Repo Tracker](https://travis-ci.org/jeking3/boost-merge-reminder) identifies many repositories using Boost.CI and
the [CMT Status Spreadsheet](https://docs.google.com/spreadsheets/d/1aFdTMdJmmD9L5IyvJx-nj3BrMVztmlNo8QwyEzLD2io/edit?usp=sharing) shows the current state of each.
There may be additional repositories using Boost.CI that are not listed.  Boost.CI does not track usage internally.

## How It Works ##

The files `.appveyor.yml`, `.azure-pipeline.yml` and `.travis.yml` must exist in your repository and will contain your customizations for build types, languages, and platforms.  The templates provided will get you started with the build jobs listed below.

These scripts will copy resources from the Boost.CI repository when needed in order to provide scripting necessary to run all these jobs successfully.

Build jobs that will severely impact performance (such as `valgrind`) will define `BOOST_NO_STRESS_TEST` so those can be skipped or hobbled.

## Topic Branch Support ##

The configuration for Travis CI and Appveyor allow for automated branch builds on branch pushes matching these names:

- master
- develop
- bugfix/*
- feature/*
- fix/*
- pr/*

## Defaults, Builds and Services ##

By default all of the builds target C++11 unless otherwise specified.
To see what kind of coverage these builds provide, see some build results:

    AppVeyor : https://ci.appveyor.com/project/jeking3/uuid-gaamf/builds/19987101
    Travis CI: https://travis-ci.org/boostorg/uuid/builds/449557162

Without any customization the scripts can provide the following services (example, see the actual CI scripts for current configurations):

| CI        | description             | toolset     | cxxflags/std                  | address-model | variant         |
| :-------- | :---------------------- | :---------- | :---------------------------- | :------------ | :-------------- |
| Appveyor  | MSVC 2019 C++2a Strict  | `msvc-14.2` | `2a`, `-permissive-`          | `64`          | `release`       |
| Appveyor  | MSVC 2017 C++2a Strict  | `msvc-14.1` | `2a`, `-permissive-`          | `64`          | `release`       |
| Appveyor  | MSVC 2017 C++17         | `msvc-14.1` | `17`                          | `64`          | `debug`         |
| Appveyor  | MSVC 2017 C++17         | `clang-win` | `11`                          | `64`          | `release`       |
| Appveyor  | MSVC 2017 C++14 Default | `msvc-14.1` | default (14)                  | `32,64`       | `release`       |
| Appveyor  | MSVC 2015 C++14 Default | `msvc-14.0` | default (14)                  | `32,64`       | `debug`         |
| Appveyor  | MSVC 2013               | `msvc-12.0` | default (most of 11)          | default       | `release`       |
| Appveyor  | MSVC 2012               | `msvc-11.0` | default (some of 11)          | default       | `release`       |
| Appveyor  | MSVC 2010               | `msvc-10.0` | default (some of 0x)          | default       | `release`       |
| Appveyor  | cygwin                  | `gcc`       | `03,11`                       | `32`          | `debug`         |
| Appveyor  | cygwin64                | `gcc`       | `11,17`                       | `64`          | `release`       |
| Appveyor  | mingw                   | `gcc`       | `03,11`                       | `32`          | `debug`         |
| Appveyor  | mingw64                 | `gcc`       | `11,17`                       | `64`          | `release`       |
| Azure P.  | gcc 4.8                 | `gcc-4.8`   | `03,11`                       | default       | `debug,release` | 
| Azure P.  | gcc 4.9                 | `gcc-4.9`   | `03,11`                       | default       | `debug,release` | 
| Azure P.  | gcc 5                   | `gcc-5`     | `11`                          | default       | `debug,release` | 
| Azure P.  | gcc 6                   | `gcc-6`     | `11,14`                       | default       | `debug,release` | 
| Azure P.  | gcc 7                   | `gcc-7`     | `11,14,17`                    | default       | `debug,release` | 
| Azure P.  | gcc 8                   | `gcc-8`     | `14,17,2a`                    | default       | `debug,release` | 
| Azure P.  | clang-3.5               | `clang-3.5` | `03,11`                       | default       | `debug,release` | 
| Azure P.  | clang-3.6               | `clang-3.6` | `03,11`                       | default       | `debug,release` | 
| Azure P.  | clang-3.7               | `clang-3.7` | `03,11`                       | default       | `debug,release` | 
| Azure P.  | clang-3.8               | `clang-3.8` | `03,11,14`                    | default       | `debug,release` | 
| Azure P.  | clang-3.9               | `clang-3.8` | `03,11,14`                    | default       | `debug,release` | 
| Azure P.  | clang-4.0               | `clang-4.0` | `11,14,17`                    | default       | `debug,release` | 
| Azure P.  | clang-5.0               | `clang-5.0` | `11,14,17`                    | default       | `debug,release` | 
| Azure P.  | clang-6.0               | `clang-6.0` | `14,17,2a`                    | default       | `debug,release` | 
| Azure P.  | clang-6.0-libc++        | `clang-6.0` | `03,11,14,17,2a`, `libc++`    | default       | `debug,release` | 
| Azure P.  | clang-7                 | `clang-7`   | `14,17,2a`                    | default       | `debug,release` | 
| Azure P.  | clang-8                 | `clang-8`   | `14,17,2a`                    | default       | `debug,release` | 
| Azure P.  | MSVC 2019 C++2a Strict  | `msvc-14.2` | `2a`, `-permissive-`          | `64`          | `debug,release` |
| Azure P.  | MSVC 2017 C++2a Strict  | `msvc-14.1` | `2a`, `-permissive-`          | `64`          | `debug,release` |
| Azure P.  | MSVC 2017 C++17         | `msvc-14.1` | `17`                          | `32,64`       | `debug,release` |
| Azure P.  | MSVC 2017 C++14 Default | `msvc-14.1` | default (14)                  | `32,64`       | `debug,release` |
| Azure P.  | MSVC 2015 C++14 Default | `msvc-14.0` | default (14)                  | `32,64`       | `debug,release` |
| Azure P.  | Xcode 10.1              | `clang`     | `14,17,2a`                    | default       | `debug,release` |
| Azure P.  | Xcode 10.0              | `clang`     | `14,17,2a`                    | default       | `debug,release` |
| Azure P.  | Xcode 9.4.1             | `clang`     | `11,14,17`                    | default       | `debug,release` |
| Azure P.  | Xcode 9.4               | `clang`     | `11,14,17`                    | default       | `debug,release` |
| Azure P.  | Xcode 9.3.1             | `clang`     | `11,14`                       | default       | `debug,release` |
| Azure P.  | Xcode 9.3               | `clang`     | `11,14`                       | default       | `debug,release` |
| Azure P.  | Xcode 9.2               | `clang`     | `11,14`                       | default       | `debug,release` |
| Azure P.  | Xcode 9.1               | `clang`     | `03,11`                       | default       | `debug,release` |
| Azure P.  | Xcode 9.0.1             | `clang`     | `03,11`                       | default       | `debug,release` |
| Azure P.  | Xcode 9.0               | `clang`     | `03,11`                       | default       | `debug,release` |
| Azure P.  | Xcode 8.3.3             | `clang`     | `03,11`                       | default       | `debug,release` |
| Travis CI | gcc 4.8                 | `gcc-4.8`   | `03,11`                       | default       | `release`       | 
| Travis CI | gcc 4.9                 | `gcc-4.9`   | `03,11`                       | default       | `release`       | 
| Travis CI | gcc 5                   | `gcc-5`     | `03,11`                       | default       | `release`       | 
| Travis CI | gcc 6                   | `gcc-6`     | `11,14`                       | default       | `release`       | 
| Travis CI | gcc 7                   | `gcc-7`     | `14,17`                       | default       | `release`       | 
| Travis CI | gcc 8                   | `gcc-8`     | `17,2a`                       | default       | `release`       | 
| Travis CI | gcc 9                   | `gcc-9`     | `17,2a`                       | default       | `release`       | 
| Travis CI | clang-3.8               | `clang-3.8` | `03,11`                       | default       | `release`       | 
| Travis CI | clang-4.0               | `clang-4.0` | `11,14`                       | default       | `release`       | 
| Travis CI | clang-5.0               | `clang-5.0` | `11,14`                       | default       | `release`       | 
| Travis CI | clang-6.0               | `clang-6.0` | `14,17`                       | default       | `release`       | 
| Travis CI | clang-6.0-libc++        | `clang-6.0` | `03,11,14`, `libc++`          | default       | `release`       | 
| Travis CI | clang-7                 | `clang-7`   | `17,2a`                       | default       | `release`       | 
| Travis CI | clang-8                 | `clang-8`   | `17,2a`                       | default       | `release`       | 
| Travis CI | osx (clang)             | `clang`     | `03,11,17`                    | default       | `release`       |
| Travis CI | big-endian              | `gcc`       | default                       | default       | `debug`         |
| Travis CI | codecov.io              | `gcc-8`     | default                       | default       | `debug`         |
| Travis CI | covscan                 | `clang`     | default                       | default       | `debug`         |
| Travis CI | asan                    | `gcc-8`     | `03,11,14`                    | default       | `debug`         |
| Travis CI | tsan                    | `gcc-8`     | `03,11,14`                    | default       | `debug`         |
| Travis CI | ubsan                   | `gcc-8`     | `03,11,14`                    | default       | `debug`         |
| Travis CI | valgrind                | `clang-6.0` | `03,11,14`                    | default       | `debug`         |
