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

namespace boost
{
  namespace boost_ci
  {
#ifdef BOOST_MSVC
#define MSVC_VALUE true
#else
#define MSVC_VALUE false
#endif

    // Some function to test
    BOOST_NOINLINE int get_answer(const bool isMsvc = MSVC_VALUE)
    {
      int answer;
      // Specifically crafted condition to check for coverage from MSVC and non MSVC builds
      if(isMsvc)
        answer = 21;
      else
        answer = 42;
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
