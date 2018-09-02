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

# valgrind (even 3.13) is missing some suppressions, so...

pushd /tmp
git clone git://sourceware.org/git/valgrind.git
cd valgrind
if [[ ! -z "$VALGRIND_COMMIT" ]]; then
  git checkout $VALGRIND_COMMIT
fi

./autogen.sh
./configure --prefix=/tmp/vg
make -j3
make -j3 install
popd

export PATH=/tmp/vg/bin:$PATH

ci/travis/build.sh

