#! /bin/bash
#
# Copyright 2022 Alexander Grund
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at
#      http://www.boost.org/LICENSE_1_0.txt)
#
# Bash script to test consuming a Boost library via CMakes add_subdirectory command
#
# Requires the following env vars:
# - BOOST_ROOT & SELF (setup step)
# - BCM_GENERATOR
# - BCM_BUILD_TYPE
# - BCM_SHARED_LIBS

set -eu

. "$(dirname "${BASH_SOURCE[0]}")"/set_num_jobs.sh

cmake_test_folder="$BOOST_ROOT/libs/$SELF/test/cmake_test"
# New unified folder used for the subdir and install test with BOOST_CI_INSTALL_TEST to distinguish in CMake
if [ -d "$cmake_test_folder" ]; then
    echo "Using the unified test folder $cmake_test_folder"
    
else
    cmake_test_folder="$BOOST_ROOT/libs/$SELF/test/cmake_subdir_test"
    echo "Using the dedicated subdir test folder $cmake_test_folder"
fi

cd "$cmake_test_folder"
mkdir __build_cmake_subdir_test__ && cd __build_cmake_subdir_test__

echo "Configuring..."
cmake -G "$BCM_GENERATOR" -DCMAKE_BUILD_TYPE=$BCM_BUILD_TYPE -DBUILD_SHARED_LIBS=$BCM_SHARED_LIBS -DBOOST_CI_INSTALL_TEST=OFF ..

echo "Building..."
cmake --build . --config $BCM_BUILD_TYPE -j$B2_JOBS

echo "Testing..."
ctest --output-on-failure --build-config $BCM_BUILD_TYPE
