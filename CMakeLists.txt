# Copyright 2018-2021 Peter Dimov
# Copyright 2021 Alexander Grund
# Distributed under the Boost Software License, Version 1.0.
# See accompanying file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt

cmake_minimum_required(VERSION 3.5...3.16)

project(boost_ci VERSION "${BOOST_SUPERPROJECT_VERSION}" LANGUAGES CXX)

add_library(boost_boost_ci src/boost_ci.cpp)
add_library(Boost::boost_ci ALIAS boost_boost_ci)

target_include_directories(boost_boost_ci PUBLIC include)

target_link_libraries(boost_boost_ci
  PUBLIC
    Boost::config
  PRIVATE
    Boost::atomic
)

if(BUILD_SHARED_LIBS)
  target_compile_definitions(boost_boost_ci PUBLIC BOOST_BOOST_CI_DYN_LINK)
endif()

if(BUILD_TESTING)
  add_subdirectory(test)
endif()
