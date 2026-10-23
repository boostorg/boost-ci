//
// Copyright (c) 2022-2026 Alexander Grund
//
// Use, modification and distribution is subject to the Boost Software License,
// Version 1.0. (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)

#define BOOST_BOOST_CI_SOURCE

#include <boost/boost-ci/boost_ci.hpp>
// Just some dependency on another Boost library
#include <boost/atomic/atomic.hpp>

#if !(defined(BOOST_NO_CXX11_HDR_FUNCTIONAL) || defined(BOOST_NO_CXX11_RVALUE_REFERENCES) || defined(BOOST_NO_CXX11_AUTO_DECLARATIONS))
#define BOOST_BOOST_CI_TEST_BIND_ISSUE
#include <functional>
#include <map>
#endif
#include <utility>

// Some simple struct big enough so that the atomic is forced to use a lock
// forcing it to call into the library
struct X
{
  double x, y, z;
  explicit X(int value = 0): x(value), y(value), z(value) {}
};

namespace boost
{
  namespace boost_ci
  {
    void reproducer();
    // Some function to test
    int get_answer(const int isMsvc)
    {
      reproducer();
      boost::atomic<X> answer;
      // Specifically crafted condition to check for coverage from MSVC and non MSVC builds
      if(isMsvc == 1)
        answer = X(21);
      else if(isMsvc == 0)
        answer = X(42);
      else
        throw example_error();
#ifdef BOOST_NO_CXX11_SMART_PTR
      return answer.load().x;
#else
      // Just use some stdlib feature combined with a Boost.Config feature as demonstration
      auto ptr = std::unique_ptr<int>(new int(answer.load().x));
      return *ptr;
#endif
    }

#ifdef BOOST_BOOST_CI_TEST_BIND_ISSUE
    // Reproducer for a bug observed in Clang 16 with libstdc++
    void f(const std::pair<int, float>&) {}

    void reproducer() {
      std::map<int, float> m{{0, 0.f}, {1, 1.f}};

      // Bind a map element (value_type is pair<const int, float>).
      auto bound = std::bind(f, *m.begin());

      // The libstdc++ failure happens during instantiation of the defaulted move constructor of std::_Bind,
      // when it checks whether std::pair can be constructed from the internal tuple-like storage.
      auto bound2 = std::move(bound);
      (void)bound2;
    }
#else
    void reproducer() {}
#endif
  }
}
