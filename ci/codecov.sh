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
# Call with either "setup" or "upload" as parameter

set -ex

. $(dirname "${BASH_SOURCE[0]}")/enforce.sh

if [[ "$1" == "setup" ]]; then
    export B2_VARIANT=debug
    if [ -z "$B2_CI_VERSION" ]; then
        export B2_CXXFLAGS="${B2_CXXFLAGS:+$B2_CXXFLAGS }cxxflags=-fprofile-arcs cxxflags=-ftest-coverage cxxflags=--coverage"
    else
        export B2_CXXFLAGS="${B2_CXXFLAGS:+$B2_CXXFLAGS }-fprofile-arcs -ftest-coverage --coverage"
    fi
    export B2_LINKFLAGS="${B2_LINKFLAGS:+$B2_LINKFLAGS }--coverage"

elif [[ "$1" == "upload" ]]; then
    if [ -z "$GCOV" ]; then
        # enforce.sh ensures B2_COMPILER
        COMPILER=${B2_COMPILER}
        COMPILER_FAMILY=$(echo ${COMPILER} | cut -d'-' -f1)
        COMPILER_EDITION=$(echo ${COMPILER} | cut -d'-' -f2)
        # clang is still not working - need a llvm-cov wrapper and fixup pathing
        if [ "${COMPILER_FAMILY}" == "clang" ]; then
            echo "clang is not supported for coverage yet"
            exit 1
            # find /usr/lib -name 'llvm-cov*' -print
            # LLVM_COV_PATH=$(find /usr/lib -type f -name llvm-cov -exec dirname {} \;)
            # export PATH=${LLVM_COV_PATH}:${PATH}
            # GCOV=llvm-cov
        elif [ "${COMPILER_FAMILY}" == "gcc" ]; then
            # cutting "gcc" above yields "gcc" for both values if no version present
            if [ "${COMPILER_EDITION}" == "${COMPILER_FAMILY}" ]; then
                GCOV=gcov
            else
                GCOV=gcov-${COMPILER_EDITION}
            fi
        else
            echo "Cannot determine GCOV."
            exit 1
        fi
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
    : "${LCOV_BRANCH_COVERAGE:=1}" # On by default, job can override but advise against it

    # coverage files are in ../../b2 from this location
    lcov --rc lcov_branch_coverage=${LCOV_BRANCH_COVERAGE} --gcov-tool=${GCOV} --directory "${BOOST_ROOT}" --capture --output-file all.info
    lcov --rc lcov_branch_coverage=${LCOV_BRANCH_COVERAGE} --list all.info  # mostly for debug but interesting to see everything captured

    # this is tricky; not all of the headers in the project go into a directory with the project
    # name, so we have to itemize all of them and extract them, along with anything in the project
    # directory including tests - after this we drop coverage on test files to finalize things
    for f in `for f in include/boost/*; do echo $f; done | cut -f2- -d/`; do echo "*/$f*"; done > /tmp/interesting
    echo headers that matter:
    cat /tmp/interesting
    xargs -L 999999 -a /tmp/interesting lcov --rc lcov_branch_coverage=${LCOV_BRANCH_COVERAGE} --extract all.info {} "*/libs/$SELF/*" --output-file "${SELF}-all.info"
    lcov --rc lcov_branch_coverage=${LCOV_BRANCH_COVERAGE} --list "${SELF}-all.info"

    # drop coverage on test files
    lcov --rc lcov_branch_coverage=${LCOV_BRANCH_COVERAGE} --remove "${SELF}-all.info" "*/${SELF}/test/*" -o "coverage.info"

    # dump a summary on the console
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
    ./codecov --verbose --nonZero ${CODECOV_NAME:+--name "$CODECOV_NAME"}
else
    echo "Invalid parameter for codecov.sh: '$1'." >&2
    false
fi
