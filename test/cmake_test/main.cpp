#include <boost/boost-ci/boost_ci.hpp>

int main()
{
    const int expectedValue = (MSVC_VALUE) ? 21 : 42;
    return (boost::boost_ci::get_answer() == expectedValue) ? 0 : 1;
}
