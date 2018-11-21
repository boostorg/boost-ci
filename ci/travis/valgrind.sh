#!/bin/bash
#
# Copyright 2018 James E. King III
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at
#      http://www.boost.org/LICENSE_1_0.txt)
#
# Bash script to run in travis to perform a cppcheck
# cwd should be $BOOST_ROOT before running
#

set -ex

# default language level: c++03
if [[ -z "$CXXSTD" ]]; then
    CXXSTD=03
fi

# required for valgrind to work:
apt-get install libc6-dbg

# valgrind on travis is 3.10 which is old
# using valgrind 3.14 but we have to build it

pushd /tmp
git clone git://sourceware.org/git/valgrind.git
cd valgrind
git checkout VALGRIND_3_14_0

./autogen.sh
./configure --prefix=/tmp/vg
make -j3
make -j3 install
popd

export PATH=/tmp/vg/bin:$PATH

ci/travis/build.sh

