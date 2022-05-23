# Copyright 2021 Alexander Grund
# Distributed under the Boost Software License, Version 1.0.
# See accompanying file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt

cmake_minimum_required(VERSION 3.5...3.16)

project(cmake_subdir_test LANGUAGES CXX)

# Those 2 should work the same
# while using find_package for the installed Boost avoids the need to manually specify dependencies
if(BOOST_CI_INSTALL_TEST)
    find_package(boost_boost_ci REQUIRED)
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
      static_assert
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