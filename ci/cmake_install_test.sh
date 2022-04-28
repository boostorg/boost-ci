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

echo "Installing Boost via CMake"
BCM_INSTALL_PATH=/tmp/boost_install

BCM_ARGS=(
    -DCMAKE_INSTALL_PREFIX=$BCM_INSTALL_PATH
)
BCM_TARGET=install

. "$(dirname "${BASH_SOURCE[0]}")"/cmake_build.sh

cmake_test_folder="$BOOST_ROOT/libs/$SELF/test/cmake_test"
# New unified folder used for the subdir and install test with BOOST_CI_INSTALL_TEST to distinguish in CMake
if [ -d "$cmake_test_folder" ]; then
    echo "Using the unified test folder $cmake_test_folder"
    
else
    cmake_test_folder="$BOOST_ROOT/libs/$SELF/test/cmake_install_test"
    echo "Using the dedicated install test folder $cmake_test_folder"
fi

cd "$cmake_test_folder"
mkdir __build_cmake_install_test__ && cd __build_cmake_install_test__

echo "Configuring..."
cmake -G "$BCM_GENERATOR" -DCMAKE_BUILD_TYPE=$BCM_BUILD_TYPE -DBUILD_SHARED_LIBS=$BCM_SHARED_LIBS -DBOOST_CI_INSTALL_TEST=ON -DCMAKE_PREFIX_PATH=$BCM_INSTALL_PATH ..

echo "Building..."
cmake --build . --config $BCM_BUILD_TYPE -j$B2_JOBS

echo "Testing..."
ctest --output-on-failure --build-config $BCM_BUILD_TYPE
