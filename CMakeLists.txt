# Copyright 2018-2021 Peter Dimov
# Copyright 2021 Alexander Grund
# Distributed under the Boost Software License, Version 1.0.
# See accompanying file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt

cmake_minimum_required(VERSION 3.5...3.16)

project(boost_ci VERSION "${BOOST_SUPERPROJECT_VERSION}" LANGUAGES CXX)

add_library(boost_boost_ci INTERFACE)
add_library(Boost::boost_ci ALIAS boost_boost_ci)

if(NOT CMAKE_VERSION VERSION_LESS "3.19")
  file(GLOB_RECURSE headers include/*.hpp)
  target_sources(boost_boost_ci PRIVATE ${headers})
endif()

target_include_directories(boost_boost_ci INTERFACE include)

target_link_libraries(boost_boost_ci
  INTERFACE
    Boost::config
)

if(BUILD_TESTING)
  add_subdirectory(test)
endif()
