![Boost](images/boost.png  "Boost")

# Boost.CI

## GitHub Actions

These instructions allow you set up GitHub Actions for your repository.  It is assumed you are a repository
administrator and that you can modify actions secrets as well as push branches directly into your repository.

The instructions will take you through:

1. Preparing for code coverage with codecov.io.
2. Preparing for static code analysis with Coverity Scan.
3. Copying the necessary files.
4. Customizing the build options.
5. Pushing a branch to test the build.
6. Committing the changes to develop, then master.

### Code Coverage (codecov.io)

1. Obtain the upload token for your project and add it to your repository:
   1. Log into codecov.io and visit the General settings (example: `https://app.codecov.io/gh/boostorg/<mylibrary>/config/general`).
   2. Copy the `CODECOV_TOKEN`.
   3. Go to your GitHub secrets page (example: `https://github.com/boostorg/<mylibrary>/settings/secrets/actions`).
   4. Add the secret as `CODECOV_TOKEN`.
2. Obtain the badge id for your project and add it to your README.md:
   1. Log into codecov.io and visit the Badges and Graphs settings (example: `https://app.codecov.io/gh/boostorg/<mylibrary>/config/badge`).
   2. Locate the badge id (unfortunately called token=) in the given URLs and update your README.md links for codecov.

### Coverity Scan (scan.coverity.com)

1. Log into scan.coverity.com and then find or create a project.
2. Obtain the upload token for your project and add it to your repository:
   1. Log into scan.coverity.com and visit the Project settings (example: `https://scan.coverity.com/projects/boostorg-<mylibrary>?tab=project_settings`).
   2. Copy the project token.
   3. Go to your GitHub secrets page (example: `https://github.com/boostorg/<mylibrary>/settings/secrets/actions`).
   4. Add the secret as `COVERITY_SCAN_TOKEN`.
   5. Add your email address as `COVERITY_SCAN_NOTIFICATION_EMAIL`.

### Files to Copy

Make a new branch called `fix/ci` from your current `develop`.  You will push this branch into your repo to trigger test builds before committing the changes.

1. Copy the `.github/workflows/ci.yml` file from this repository into the the same folder in your repository.  If you examine the file it will trigger the Boost.CI
   workflow in a variety of conditions including on pull requests, tags, and when certain branches are pushed.
1. Copy the `.codecov.yml` file from this repository to the top level of your repository and edit if required.
1. Copy the `LICENSE` file from this repository to the top level of your repository.  This adds the `BSL-1.0` designation to your repository on github.
1. [optional] Copy the `README.template.md` file from this repository to the top level `README.md` of your repository.  If you already have a README.md then you can take what you need from the template version to improve it, if desired.  Otherwise, you will need to customize README.md for your repository.  One useful step is to fixup the repository name using the command `sed -i 's/template/<myrepositoryname>/g' README.md`, and then update the first line description.  You can also use the tools/makebadges.sh script in this repository to freshen your badge section.

### Customizing the Build Options

The build options are defined in `.github/workflows/reusable.yml`.  The defaults should work for the majority of cases.

If you use the default setting for enable_cmake then you need to provide a test/cmake_test (see boostorg/format for an example).

### Push to Test

Push to the fix/ci branch in your repository then check the Actions tab to see the build.  Fix issues.

### Push to Enable

Push to the develop branch, then master branch once that build completes.
