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
# - BCM_ARGS
# - BCM_TARGET

set -e

. "$(dirname "${BASH_SOURCE[0]}")"/set_num_jobs.sh

cd "$BOOST_ROOT"
buildDir=__build
while [ -d "$buildDir" ]; do
    buildDir="${buildDir}_2"
done
mkdir "$buildDir" && cd "$buildDir"

echo "Configuring..."
set -x
cmake -G "$BCM_GENERATOR" -DCMAKE_BUILD_TYPE=$BCM_BUILD_TYPE -DBUILD_SHARED_LIBS=$BCM_SHARED_LIBS -DBOOST_INCLUDE_LIBRARIES=$SELF -DBoost_VERBOSE=ON "${BCM_ARGS[@]}" ..
set +x

echo "Building..."
cmake --build . --target $BCM_TARGET --config $BCM_BUILD_TYPE -j$B2_JOBS
