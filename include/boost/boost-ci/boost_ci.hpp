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

namespace boost
{
  namespace boost_ci
  {
    class BOOST_SYMBOL_VISIBLE example_error : public std::runtime_error {
    public:
      example_error() : std::runtime_error("Example error for demonstration") {}
    };

    // Some function to test
    BOOST_NOINLINE int get_answer(const int isMsvc = MSVC_VALUE)
    {
      int answer;
      // Specifically crafted condition to check for coverage from MSVC and non MSVC builds
      if(isMsvc == 0)
        answer = 42;
      else if(isMsvc == 1)
        answer = 21;
      else
        throw example_error();

#ifdef BOOST_NO_CXX11_SMART_PTR
      return answer;
#else
      // Just use some stdlib feature combined with a Boost.Config feature as demonstration
      auto ptr = std::unique_ptr<int>(new int(answer));
      return *ptr;
#endif
    }
  }
}
