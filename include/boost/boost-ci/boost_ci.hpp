//
// Copyright (c) 2020-2021 Alexander Grund
//
// Use, modification and distribution is subject to the Boost Software License,
// Version 1.0. (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)

// Just something so we can test dependencies on other Boost libs
#include <boost/config.hpp>
#include <stdexcept>
#ifndef BOOST_NO_CXX11_SMART_PTR
#include <memory>
#endif

#ifdef BOOST_MSVC
#define MSVC_VALUE 1
#else
#define MSVC_VALUE 0
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
    class BOOST_SYMBOL_VISIBLE example_error : public std::runtime_error {
    public:
      example_error() : std::runtime_error("Example error for demonstration") {}
    };

    // Some function to test. Returns 41 for 0, 42 for 1 and throws for other values
    BOOST_BOOST_CI_DECL int get_answer(int isMsvc = MSVC_VALUE);
  }
}
