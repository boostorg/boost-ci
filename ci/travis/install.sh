#! /bin/bash
#
# Copyright 2017 - 2019 James E. King III
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at
#      http://www.boost.org/LICENSE_1_0.txt)
#
# Executes the install phase for travis
#
# If your repository has additional directories beyond
# "example", "examples", "tools", and "test" then you
# can add them in the environment variable DEPINST.
# i.e. - DEPINST="--include dirname1 --include dirname2"
#

set -ex

if [ "$TRAVIS_OS_NAME" == "osx" ]; then
    unset -f cd
fi

export BOOST_CI_TARGET_BRANCH="$TRAVIS_BRANCH"
export BOOST_CI_SRC_FOLDER="$TRAVIS_BUILD_DIR"

# Translate the `compiler: xxx` setting from travis into a toolset when B2_TOOLSET isn't set
export B2_COMPILER=$TRAVIS_COMPILER
if [ "${B2_TOOLSET:-}" == "" ]; then
    if [[ "$TRAVIS_COMPILER" =~ clang ]]; then
        export B2_TOOLSET=clang
    elif [[ "$TRAVIS_COMPILER" =~ g\+\+ ]]; then
        export B2_TOOLSET=gcc
    else
        echo "Unknown TRAVIS_COMPILER=$TRAVIS_COMPILER. Set B2_TOOLSET instead!" >&2
        false
    fi
    echo "using $B2_TOOLSET : : $TRAVIS_COMPILER ;" > ~/user-config.jam
fi

. $(dirname "${BASH_SOURCE[0]}")/../common_install.sh
