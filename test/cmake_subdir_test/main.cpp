#include <boost/boost-ci/boost_ci.hpp>

int main()
{
    return (boost::boost_ci::get_answer() == 42) ? 0 : 1;
}
