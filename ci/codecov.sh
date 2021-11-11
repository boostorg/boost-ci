#! /bin/bash
#
# Copyright 2017 - 2019 James E. King III
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
# Call with either "collect" or "upload" as parameter

set -ex

. $(dirname "${BASH_SOURCE[0]}")/enforce.sh

if [[ "$1" == "collect" ]]; then
    export B2_VARIANT=debug
    export B2_CXXFLAGS="${B2_CXXFLAGS:+$B2_CXXFLAGS }-fkeep-static-functions --coverage"
    export B2_LINKFLAGS="${B2_LINKFLAGS:+$B2_LINKFLAGS }--coverage"
    $(dirname "${BASH_SOURCE[0]}")/build.sh

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
    git clone -b v1.14 https://github.com/linux-test-project/lcov.git
    export PATH=/tmp/lcov/bin:$PATH
    command -v lcov
    lcov --version

    # switch back to the original source code directory
    cd $BOOST_CI_SRC_FOLDER
    : "${LCOV_BRANCH_COVERAGE:=1}" # Set default

    # coverage files are in ../../b2 from this location
    lcov --gcov-tool=$GCOV --rc lcov_branch_coverage=${LCOV_BRANCH_COVERAGE} --base-directory "$BOOST_ROOT/libs/$SELF" --directory "$BOOST_ROOT" --capture --output-file all.info
    # dump a summary on the console
    lcov --list all.info

    # all.info contains all the coverage info for all projects - limit to ours
    # first we extract the interesting headers for our project then we use that list to extract the right things
    for f in `for f in include/boost/*; do echo $f; done | cut -f2- -d/`; do echo "*/$f*"; done > /tmp/interesting
    echo headers that matter:
    cat /tmp/interesting
    xargs -L 999999 -a /tmp/interesting lcov --gcov-tool=$GCOV --rc lcov_branch_coverage=${LCOV_BRANCH_COVERAGE:-1} --extract all.info {} "*/libs/$SELF/*" --output-file coverage.info

    # dump a summary on the console - helps us identify problems in pathing
    lcov --list coverage.info

    #
    # upload to codecov.io
    #
    curl -Os https://uploader.codecov.io/latest/linux/codecov
    chmod +x codecov
    ./codecov -f coverage.info
fi
