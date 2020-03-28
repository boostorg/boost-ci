#! /bin/bash
#
# Copyright 2017 - 2019 James E. King III
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at
#      http://www.boost.org/LICENSE_1_0.txt)
#
# Bash script to run in travis to perform a bjam build
# cwd should be $BOOST_ROOT/libs/$SELF before running
#

set -ex

. "$(dirname "${BASH_SOURCE[0]}")"/enforce.sh

export UBSAN_OPTIONS=print_stacktrace=1

cd "$BOOST_ROOT"

./b2 libs/$SELF/test \
    toolset="$B2_TOOLSET" \
    cxxstd="$B2_CXXSTD" \
    $B2_CXXFLAGS \
    ${B2_DEFINES:+defines=$B2_DEFINES} \
    ${B2_INCLUDE:+include=$B2_INCLUDE} \
    ${B2_LINKFLAGS:+linkflags=$B2_LINKFLAGS} \
    ${B2_TESTFLAGS} \
    ${B2_ADDRESS_MODEL:+address-model=$B2_ADDRESS_MODEL} \
    ${B2_LINK:+link=$B2_LINK} \
    ${B2_VISIBILITY:+visibility=$B2_VISIBILITY} \
    ${B2_STDLIB:+"-stdlib=$B2_STDLIB"} \
    ${B2_THREADING} \
    ${B2_VARIANT:+variant=$B2_VARIANT} \
    ${B2_ASAN:+address-sanitizer=norecover} \
    ${B2_UBSAN:+thread-sanitizer=norecover} \
    ${B2_TSAN:+undefined-sanitizer=norecover} \
    -j${B2_JOBS} \
    ${B2_FLAGS} \
    "$@"
