#! /bin/bash
#
# Copyright 2022 Alexander Grund
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at
#      http://www.boost.org/LICENSE_1_0.txt)
#
# Bash script to perform a CMake build of Boost
#
# Requires the following env vars:
# - BOOST_ROOT & SELF (setup step)
# - BCM_GENERATOR
# - BCM_BUILD_TYPE
# - BCM_SHARED_LIBS

set -e

BCM_ARGS=(
    -DBUILD_TESTING=ON
)
BCM_TARGET=tests
 
. "$(dirname "${BASH_SOURCE[0]}")"/cmake_build.sh

echo "Testing..."
ctest --output-on-failure --build-config $BCM_BUILD_TYPE
