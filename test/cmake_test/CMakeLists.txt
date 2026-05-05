# Copyright 2021-2026 Alexander Grund
# Distributed under the Boost Software License, Version 1.0.
# See accompanying file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt

cmake_minimum_required(VERSION 3.5...3.31)

project(cmake_subdir_test LANGUAGES CXX)

# Those 2 should work the same
# while using find_package for the installed Boost avoids the need to manually specify dependencies
if(BOOST_CI_INSTALL_TEST)
    find_package(Boost COMPONENTS boost_ci REQUIRED)
    # Header-only libraries can use the following instead until B2 also installs targets for them
    if(BOOST_CI_INSTALLED_BY STREQUAL "B2")
        find_package(Boost COMPONENTS headers REQUIRED)
        # To avoid changing the target name compared to the installed-by-CMake case, a hack like this can be used:
        # add_library(Boost::boost_ci ALIAS Boost::headers)
    endif()
else()
    add_subdirectory(../.. boostorg/boost-ci)

    set(deps
      # Primary dependencies
      atomic
      config
      core
      # Secondary dependencies
      align
      assert
      predef
      preprocessor
      throw_exception
      type_traits
      winapi
    )

    foreach(dep IN LISTS deps)
      add_subdirectory(../../../${dep} boostorg/${dep})
    endforeach()
endif()

add_executable(main main.cpp)
target_link_libraries(main Boost::boost_ci)

enable_testing()
add_test(NAME main COMMAND main)

add_custom_target(check COMMAND ${CMAKE_CTEST_COMMAND} --output-on-failure -C $<CONFIG>)
