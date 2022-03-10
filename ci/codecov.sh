#! /bin/bash
#
# Copyright 2017 - 2022 James E. King III
# Copyright 2021 Alexander Grund
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at
#      http://www.boost.org/LICENSE_1_0.txt)
#
# Bash script to to perform codecov.io integration
#

# Same requirements as build.sh
# Requires env vars:
# - BOOST_CI_SRC_FOLDER
# - BOOST_ROOT
# - SELF
# Call with either "setup" or "upload" as parameter

#
# If you want to exclude content from the coverage report you must check in
# a .codecov.yml file as is found in the boost-ci project, and it must be
# in the default branch for the repository.  It will not be picked up from
# a pull request.
#

set -ex

. $(dirname "${BASH_SOURCE[0]}")/enforce.sh

if [[ "$1" == "setup" ]]; then
    if [ -z "$B2_CI_VERSION" ]; then
        # Old CI version needs to use the prefixes
        export B2_VARIANT="variant=debug"
        export B2_CXXFLAGS="${B2_CXXFLAGS:+$B2_CXXFLAGS }cxxflags=-fkeep-static-functions cxxflags=--coverage"
        export B2_LINKFLAGS="${B2_LINKFLAGS:+$B2_LINKFLAGS } linkflags=--coverage"
    else
        export B2_VARIANT=debug
        export B2_CXXFLAGS="${B2_CXXFLAGS:+$B2_CXXFLAGS }-fkeep-static-functions --coverage"
        export B2_LINKFLAGS="${B2_LINKFLAGS:+$B2_LINKFLAGS }--coverage"
    fi

elif [[ "$1" == "upload" ]]; then
    if [ -z "$GCOV" ]; then
        ver=7 # default
        if [ "${B2_TOOLSET%%-*}" == "gcc" ]; then
            if [[ "$B2_TOOLSET" =~ gcc- ]]; then
                ver="${B2_TOOLSET##*gcc-}"
            elif [[ "$B2_COMPILER" =~ gcc- ]]; then
                ver="${B2_COMPILER##*gcc-}"
            fi
        fi
        GCOV=gcov-${ver}
    fi

    # install the latest lcov we know works
    rm -rf /tmp/lcov
    cd /tmp
    git clone --depth 1 -b v1.15 https://github.com/linux-test-project/lcov.git
    export PATH=/tmp/lcov/bin:$PATH
    command -v lcov
    lcov --version

    # switch back to the original source code directory
    cd $BOOST_CI_SRC_FOLDER
    : "${LCOV_BRANCH_COVERAGE:=1}" # Set default

    # coverage files are in ../../b2 from this location
    lcov --rc lcov_branch_coverage=${LCOV_BRANCH_COVERAGE} --gcov-tool=$GCOV --directory "$BOOST_ROOT" --capture --output-file all.info
    # dump a summary on the console
    lcov --rc lcov_branch_coverage=${LCOV_BRANCH_COVERAGE} --list all.info

    # all.info contains all the coverage info for all projects - limit to ours
    # first we extract the interesting headers for our project then we use that list to extract the right things
    for f in `for f in include/boost/*; do echo $f; done | cut -f2- -d/`; do echo "*/$f*"; done > /tmp/interesting
    echo headers that matter:
    cat /tmp/interesting
    xargs -L 999999 -a /tmp/interesting lcov --rc lcov_branch_coverage=${LCOV_BRANCH_COVERAGE} --extract all.info {} "*/libs/$SELF/*" --output-file coverage.info

    # dump a summary on the console - helps us identify problems in pathing
    # note this has test file coverage in it - if you do not want to count test
    # files against your coverage numbers then use a .codecov.yml file which
    # must be checked into the default branch (it is not read or used from a
    # pull request)
    lcov --rc lcov_branch_coverage=${LCOV_BRANCH_COVERAGE} --list coverage.info

    #
    # upload to codecov.io
    #
    curl -Os https://uploader.codecov.io/latest/linux/codecov
    
    # Verify Download
    if command -v gpg &> /dev/null && command -v gpgv &> /dev/null; then
        curl https://keybase.io/codecovsecurity/pgp_keys.asc | gpg --no-default-keyring --keyring trustedkeys.gpg --import

        curl -Os https://uploader.codecov.io/latest/linux/codecov.SHA256SUM
        curl -Os https://uploader.codecov.io/latest/linux/codecov.SHA256SUM.sig

        gpgv codecov.SHA256SUM.sig codecov.SHA256SUM
        shasum -a 256 -c codecov.SHA256SUM
    fi

    # Workaround for https://github.com/codecov/uploader/issues/525
    if [ -n "$GITHUB_HEAD_REF" ]; then
      export GITHUB_SHA=$(git show --no-patch --format="%P" | awk '{print $NF}')
    fi

    chmod +x codecov
    ./codecov --verbose --nonZero ${CODECOV_NAME:+--name "$CODECOV_NAME"} -f coverage.info -X search
else
    echo "Invalid parameter for codecov.sh: '$1'." >&2
    false
fi
