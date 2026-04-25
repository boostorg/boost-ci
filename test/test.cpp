//
// Copyright (c) 2020 Mateusz Loskot <mateusz@loskot.net>
//
// Use, modification and distribution is subject to the Boost Software License,
// Version 1.0. (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

// Use some STL components just to quick check compilers
#include <iostream>
#include <string>
#include <map>
#include <vector>
// Use our dummy lib
#include <boost/boost-ci/boost_ci.hpp>
// And the usual test framwork
#include <boost/core/lightweight_test.hpp>
// Check that including a file from the same directory works
#include "test2.hpp"

// Test of the CI scripts passing the correct defines
#ifdef BOOST_CI_TEST_DEFINES
    #ifndef BOOST_NO_STRESS_TEST
        #error "Missing define BOOST_NO_STRESS_TEST"
    #endif
    #ifndef BOOST_IMPORTANT
        #error "Missing define BOOST_IMPORTANT"
    #endif
    #ifndef BOOST_ALSO_IMPORTANT
        #error "Missing define BOOST_ALSO_IMPORTANT"
    #endif
    #define BOOST_CI_STRINGIZE_2(x) #x
    #define BOOST_CI_STRINGIZE(x) BOOST_CI_STRINGIZE_2(x)
#endif

#ifdef TEST_REFLECTION
#include <meta>

struct MyStruct {
    int x;
    double y;
};
#endif

int main()
{
#ifdef BOOST_CI_TEST_DEFINES
    const std::string macro_value = BOOST_CI_STRINGIZE(BOOST_ALSO_IMPORTANT);
    BOOST_TEST_EQ(macro_value, "with space");
#endif
    const bool isMSVC = MSVC_VALUE;
    std::map<std::string, std::vector<int> > map;
    map["result"].push_back(boost::boost_ci::get_answer());
    // Specifically crafted condition to check for coverage from MSVC and non MSVC builds
    if(isMSVC)
    {
      BOOST_TEST_EQ(boost::boost_ci::get_answer(), 21);
    } else
    {
      BOOST_TEST_EQ(boost::boost_ci::get_answer(), 42);
    }
    BOOST_TEST_EQ(map["result"].size(), 1u);
    BOOST_TEST_THROWS(boost::boost_ci::get_answer(-1), boost::boost_ci::example_error);

#ifdef TEST_REFLECTION
    std::cout << "Reflection enabled - Printing members of MyStruct\n";
    constexpr static auto members = std::define_static_array(
        std::meta::nonstatic_data_members_of(^^MyStruct, std::meta::access_context::unchecked())
    );
    static_assert(members.size() == 2);
    static_assert(identifier_of(members[0]) == "x");
    static_assert(identifier_of(members[1]) == "y");

    template for (constexpr auto member: members){
        std::cout << identifier_of(member) << "\n";
    }
#else
    std::cout << "Reflection disabled\n";
#endif

    return boost::report_errors();
}
