#! /bin/bash
#
# Copyright 2021 Alexander Grund
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at
#      http://www.boost.org/LICENSE_1_0.txt)
#
# Executes the install phase for GHA
# Needs env variables:
# 	- B2_COMPILER
# 	- B2_CXXSTD
# 	- B2_SANITIZE

set -ex

BOOST_CI_TARGET_BRANCH="${GITHUB_BASE_REF:-$GITHUB_REF}"
export BOOST_CI_TARGET_BRANCH="${BOOST_CI_TARGET_BRANCH##*/}" # Extract branch name
export BOOST_CI_SRC_FOLDER="${GITHUB_WORKSPACE//\\//}"

echo "BOOST_CI_TARGET_BRANCH=$BOOST_CI_TARGET_BRANCH" >> $GITHUB_ENV
echo "BOOST_CI_SRC_FOLDER=$BOOST_CI_SRC_FOLDER" >> $GITHUB_ENV

if [[ "$B2_SANITIZE" == "yes" ]]; then
  B2_ASAN=1
  B2_UBSAN=1
  if [[ -f $BOOST_CI_SRC_FOLDER/ubsan-blacklist ]]; then
    B2_CXXFLAGS="${B2_CXXFLAGS:+$B2_CXXFLAGS }-fsanitize-blacklist=libs/$SELF/ubsan-blacklist"
  fi
  if [[ -f $BOOST_CI_SRC_FOLDER/.ubsan-ignorelist ]]; then
    export UBSAN_OPTIONS="suppressions=${BOOST_CI_SRC_FOLDER}/.ubsan-ignorelist,${UBSAN_OPTIONS}"
  fi
fi

. $(dirname "${BASH_SOURCE[0]}")/../common_install.sh

# Persist the environment for all future steps

# Set by common_install.sh
echo "SELF=$SELF" >> $GITHUB_ENV
echo "BOOST_ROOT=$BOOST_ROOT" >> $GITHUB_ENV
echo "B2_TOOLSET=$B2_TOOLSET" >> $GITHUB_ENV
echo "B2_COMPILER=$B2_COMPILER" >> $GITHUB_ENV
# Usually set by the env-key of the "Setup Boost" step
[ -z "$B2_CXXSTD" ] || echo "B2_CXXSTD=$B2_CXXSTD" >> $GITHUB_ENV
[ -z "$B2_CXXFLAGS" ] || echo "B2_CXXFLAGS=$B2_CXXFLAGS" >> $GITHUB_ENV
[ -z "$B2_DEFINES" ] || echo "B2_DEFINES=$B2_DEFINES" >> $GITHUB_ENV
[ -z "$B2_INCLUDE" ] || echo "B2_INCLUDE=$B2_INCLUDE" >> $GITHUB_ENV
[ -z "$B2_LINKFLAGS" ] || echo "B2_LINKFLAGS=$B2_LINKFLAGS" >> $GITHUB_ENV
[ -z "$B2_TESTFLAGS" ] || echo "B2_TESTFLAGS=$B2_TESTFLAGS" >> $GITHUB_ENV
[ -z "$B2_ADDRESS_MODEL" ] || echo "B2_ADDRESS_MODEL=$B2_ADDRESS_MODEL" >> $GITHUB_ENV
[ -z "$B2_LINK" ] || echo "B2_LINK=$B2_LINK" >> $GITHUB_ENV
[ -z "$B2_VISIBILITY" ] || echo "B2_VISIBILITY=$B2_VISIBILITY" >> $GITHUB_ENV
[ -z "$B2_STDLIB" ] || echo "B2_STDLIB=$B2_STDLIB" >> $GITHUB_ENV
[ -z "$B2_THREADING" ] || echo "B2_THREADING=$B2_THREADING" >> $GITHUB_ENV
[ -z "$B2_VARIANT" ] || echo "B2_VARIANT=$B2_VARIANT" >> $GITHUB_ENV
[ -z "$B2_ASAN" ] || echo "B2_ASAN=$B2_ASAN" >> $GITHUB_ENV
[ -z "$B2_TSAN" ] || echo "B2_TSAN=$B2_TSAN" >> $GITHUB_ENV
[ -z "$B2_UBSAN" ] || echo "B2_UBSAN=$B2_UBSAN" >> $GITHUB_ENV
[ -z "$B2_FLAGS" ] || echo "B2_FLAGS=$B2_FLAGS" >> $GITHUB_ENV
[ -z "$BCM_GENERATOR" ] || echo "BCM_GENERATOR=$BCM_GENERATOR" >> $GITHUB_ENV
[ -z "$BCM_BUILD_TYPE" ] || echo "BCM_BUILD_TYPE=$BCM_BUILD_TYPE" >> $GITHUB_ENV
[ -z "$BCM_SHARED_LIBS" ] || echo "BCM_SHARED_LIBS=$BCM_SHARED_LIBS" >> $GITHUB_ENV
