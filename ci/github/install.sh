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
export BOOST_CI_SRC_FOLDER="$GITHUB_WORKSPACE"

echo "BOOST_CI_TARGET_BRANCH=$BOOST_CI_TARGET_BRANCH" >> $GITHUB_ENV
echo "BOOST_CI_SRC_FOLDER=$BOOST_CI_SRC_FOLDER" >> $GITHUB_ENV

# B2_COMPILER is optional, e.g. unset for CMake builds -> Only checkout
if [ -n "$B2_COMPILER" ]; then
    echo "B2_COMPILER=$B2_COMPILER" >> $GITHUB_ENV
    if [[ "$B2_COMPILER" == "clang" ]] || [[ "$B2_COMPILER" == clang-* ]]; then
      B2_TOOLSET=clang
      export CXX=${B2_COMPILER/clang/clang++}
    elif [[ "$B2_COMPILER" =~ gcc ]]; then
      B2_TOOLSET=gcc
      export CXX=${B2_COMPILER/gcc/g++}
    else
      echo "Unknown compiler: '$B2_COMPILER'. Need either clang(-version) or gcc(-version)" >&2
      false
    fi
    echo -n "using $B2_TOOLSET : : $CXX" > ~/user-config.jam
    if [ -n "$GCC_TOOLCHAIN_ROOT" ]; then
        echo -n " : <compileflags>\"--gcc-toolchain=$GCC_TOOLCHAIN_ROOT\" <linkflags>\"--gcc-toolchain=$GCC_TOOLCHAIN_ROOT\"" >> ~/user-config.jam
    fi
    echo " ;" >> ~/user-config.jam

    if [[ "$B2_COMPILER" == clang-* ]]; then
      llvmPath="/usr/lib/llvm-${B2_COMPILER#*-}/bin"
      echo "$llvmPath" >> $GITHUB_PATH
    fi

    $B2_COMPILER --version
    $CXX --version

    echo "B2_TOOLSET=$B2_TOOLSET" >> $GITHUB_ENV
fi

echo "B2_CXXSTD=$B2_CXXSTD" >> $GITHUB_ENV
if [[ "$B2_SANITIZE" == "yes" ]]; then
  echo "B2_ASAN=1" >> $GITHUB_ENV
  echo "B2_UBSAN=1" >> $GITHUB_ENV
  if [[ -f $BOOST_CI_SRC_FOLDER/ubsan-blacklist ]]; then
    echo "B2_CXXFLAGS=${B2_CXXFLAGS:+$B2_CXXFLAGS }-fsanitize-blacklist=libs/$SELF/ubsan-blacklist" >> $GITHUB_ENV
  fi
fi

. $(dirname "${BASH_SOURCE[0]}")/../common_install.sh
echo "SELF=$SELF" >> $GITHUB_ENV
echo "BOOST_ROOT=$BOOST_ROOT" >> $GITHUB_ENV
