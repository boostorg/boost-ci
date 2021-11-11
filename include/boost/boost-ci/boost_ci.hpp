//
// Copyright (c) 2020-2021 Alexander Grund
//
// Use, modification and distribution is subject to the Boost Software License,
// Version 1.0. (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)

// Just something so we can test dependencies on other Boost libs
#include <boost/config.hpp>

namespace boost
{
  namespace boost_ci
  {
    // Some function to test
    BOOST_NOINLINE int get_answer()
    {
      return 42;
    }
  }
}
