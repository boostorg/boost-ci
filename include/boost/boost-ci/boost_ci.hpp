//
// Copyright (c) 2020-2021 Alexander Grund
//
// Use, modification and distribution is subject to the Boost Software License,
// Version 1.0. (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)

// Just something so we can test dependencies on other Boost libs
#include <boost/config.hpp>
#ifndef BOOST_NO_CXX11_SMART_PTR
#include <memory>
#endif

// This define is usually set in boost/<libname>/config.hpp
#if defined(BOOST_ALL_DYN_LINK) || defined(BOOST_BOOST_CI_DYN_LINK)
#ifdef BOOST_BOOST_CI_SOURCE
#define BOOST_BOOST_CI_DECL BOOST_SYMBOL_EXPORT
#else
#define BOOST_BOOST_CI_DECL BOOST_SYMBOL_IMPORT
#endif
#else
#define BOOST_BOOST_CI_DECL
#endif

namespace boost
{
  namespace boost_ci
  {
#ifdef BOOST_MSVC
#define MSVC_VALUE true
#else
#define MSVC_VALUE false
#endif

    // Some function to test. Returns 41 for true, 42 otherwise
    BOOST_BOOST_CI_DECL int get_answer(bool isMsvc = MSVC_VALUE);
  }
}
