//
// Copyright (c) 2020 Mateusz Loskot <mateusz@loskot.net>
//
// Use, modification and distribution is subject to the Boost Software License,
// Version 1.0. (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//
#include <boost/boost-ci/boost_ci.hpp>
#include <boost/core/lightweight_test.hpp>

int main()
{
    BOOST_TEST_EQ(boost::boost_ci::get_answer(), 42);
    return boost::report_errors();
}
