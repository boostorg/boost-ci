#!/bin/bash
#
# Copyright 2020-2021 Peter Dimov
# Copyright 2021 Andrey Semashev
# Copyright 2021-2026 Alexander Grund
# Copyright 2022-2025 James E. King III
#
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at
#      http://www.boost.org/LICENSE_1_0.txt)

# Test the installed CMake config files by building and running the CMake install test.
# Environment variables:
# - SELF: the name of the library being tested
# - BOOST_ROOT: root of the boost source tree
# - BCM_INSTALL_PATH: path where the CMake config files are installed
# - B2_JOBS: number of parallel jobs to use for building
# - CI_GENERATOR: the CMake generator to use (e.g. "Ninja" or "Unix Makefiles")
# - CI_BUILD_TYPE: the build type to use (e.g. "Debug" or "Release")
# - CI_BUILD_SHARED: whether to build shared libraries (ON or OFF)
# - RUNNER_OS: the operating system (e.g. "Windows", "Linux", "macOS")

set -eux

cmake_test_folder="$BOOST_ROOT/libs/$SELF/test/cmake_test" # New unified folder
[ -d "$cmake_test_folder" ] || cmake_test_folder="$BOOST_ROOT/libs/$SELF/test/cmake_install_test"
cd "$cmake_test_folder"

rm -rf __build_cmake_install_test__
mkdir __build_cmake_install_test__ && cd __build_cmake_install_test__

unset BOOST_ROOT # Make sure CMake finds the installed config, not the source tree
cmake -DBOOST_CI_INSTALL_TEST=ON \
    -G "$CI_GENERATOR" \
    -DBUILD_SHARED_LIBS="$CI_BUILD_SHARED" \
    -DCMAKE_BUILD_TYPE="$CI_BUILD_TYPE" \
    -DCMAKE_PREFIX_PATH="$BCM_INSTALL_PATH" \
    -DCMAKE_VERBOSE_MAKEFILE=ON ..

cmake --build . --config "$CI_BUILD_TYPE" -j "$B2_JOBS"
if [[ "$CI_BUILD_SHARED" == "ON" ]]; then
    # Make sure shared libs can be found at runtime
    if [ "$RUNNER_OS" == "Windows" ]; then
        export PATH="$BCM_INSTALL_PATH/bin:$PATH"
    else
        export LD_LIBRARY_PATH="$BCM_INSTALL_PATH/lib:${LD_LIBRARY_PATH:-}"
    fi
fi
ctest --output-on-failure --build-config "$CI_BUILD_TYPE"