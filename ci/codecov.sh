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
        export B2_CXXFLAGS="${B2_CXXFLAGS:+$B2_CXXFLAGS }cxxflags=-fprofile-generate cxxflags=--coverage"
    else
        export B2_CXXFLAGS="${B2_CXXFLAGS:+$B2_CXXFLAGS }-fprofile-generate --coverage"
    fi
    export B2_LINKFLAGS="${B2_LINKFLAGS:+$B2_LINKFLAGS }--coverage"

elif [[ "$1" == "upload" ]]; then
    if [ -z "$GCOV" ]; then
        ver=7 # default
        if [ "${B2_TOOLSET%%-*}" == "gcc" ]; then
            if [[ "$B2_TOOLSET" =~ gcc- ]]; then
                ver="${B2_TOOLSET##*gcc-}"
            elif [[ "$B2_COMPILER" =~ gcc- ]]; then
                ver="${B2_COMPILER##*gcc-}"
            fi
            GCOV=gcov-${ver}
        else
            GCOV=gcov
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
    : "${LCOV_BRANCH_COVERAGE:=1}" # Set default

    # coverage files are in ../../b2 from this location
    lcov --gcov-tool=$GCOV --rc lcov_branch_coverage=${LCOV_BRANCH_COVERAGE} --directory "$BOOST_ROOT" --no-external --capture --output-file all.info
    lcov --extract all.info "**/${SELF}/**" -o "${SELF}-all.info"
    lcov --remove "${SELF}-all.info" "**/${SELF}/test/**" -o "coverage.info"

    # dump a summary on the console
    lcov --list coverage.info

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
