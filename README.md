![Boost](images/boost.png  "Boost")

# Boost.CI #

This repository contains scripts that enable continuous integration with [Appveyor](https://www.appveyor.com/), [codecov.io](https://codecov.io/), 
[Coverity Scan](https://scan.coverity.com/), and [Travis CI](https://travis-ci.org/).  These scripts are intended to be downloaded and used during boost repository builds to improve project quality.  In most cases the scripts are self-configuring.  Some integrations require additional setup actions to complete.

## Summary (TL;DR) ##

Here are all the steps you need to take as a Boost repository maintainer to enable all of these CI features in your repository:

1. Checkout `develop` and then make a new branch called `ci`.
1. Copy the `template/appveyor.yml` file from this repository into the *top level* of your repository.  The file `appveyor.yml` should be in the top level directory of your repository.
1. Copy the `template/.travis.yml` file from this repository into the top level or your repository.
1. Copy the `LICENSE` file from this repository to the top level of your repository.  This adds the `BSL-1.0` designation to your repository on github.
1. [optional] Copy the `template/README.md` file from this repository to the top level of your repository.  If you already have a README.md then you can take what you need from the template version to improve it, if desired.  Otherwise, you will need to customize README.md for your repository.  One useful step is to fixup the repository name using the command `sed -i 's/template/<myrepositoryname>/g' README.md`, and then update the first line description.
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

## How It Works ##

The files `appveyor.yml` and `.travis.yml` must exist in your repository and will contain your customizations for build types, languages, and platforms.  The templates provided will get you started with the build jobs listed below.

These scripts will copy resources from the Boost.CI repository when needed in order to provide scripting necessary to run all these jobs successfully.

## Defaults, Builds and Services ##

By default all of the builds target C++03 unless otherwise specified.

Without any customization the scripts provide the following services:

| CI | description | toolset | address-model | variant |
| :-- | :------------- | :---- | :---- | :---- |
| Appveyor | MSVC 2010 | `msvc-10.0` | default  | `debug,release` |
| Appveyor | MSVC 2012 | `msvc-11.0` | default  | `debug,release` |
| Appveyor | MSVC 2013 | `msvc-12.0` | default  | `debug,release` |
| Appveyor | MSVC 2015 | `msvc-14.0` | `32,64` | `debug,release` |
| Appveyor | MSVC 2017 | `msvc-14.1` | `32,64` | `debug,release` |
| Appveyor | cygwin | `gcc` | `32` | `debug,release`|
| Appveyor | cygwin64 | `gcc` | `64` | `debug,release`|
| Appveyor | mingw | `gcc` | `32` | `debug,release`|
| Appveyor | mingw64 | `gcc` | `64` | `debug,release`|
| Travis CI | C++03 | `gcc,gcc-7,clang` | default | `debug,release` |
| Travis CI | C++11 | `gcc,gcc-7,clang` | default | `debug,release` |
| Travis CI | valgrind | `clang` | default | `debug` |
| Travis CI | cppcheck | n/a | n/a | n/a |
| Travis CI | UBSAN | `gcc-7` | default | `debug` |
| Travis CI | codecov.io | `gcc-7` | default | `debug` |
| Travis CI | osx | `clang` | default | `debug,release` |
