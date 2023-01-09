#!/bin/bash
#
# Copyright 2018 - 2019 James E. King III
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at
#      http://www.boost.org/LICENSE_1_0.txt)
#
# Bash script to run in travis to perform a cppcheck
# cwd should be $BOOST_ROOT before running
#

set -ex

# valgrind on travis (xenial) is 3.11 which is old
# using valgrind 3.14 but we have to build it

pushd /tmp
valgrindversion=3.20.0
curl -sSL --retry ${NET_RETRY_COUNT:-5} https://sourceware.org/pub/valgrind/valgrind-${valgrindversion}.tar.bz2 --output valgrind-${valgrindversion}.tar.bz2
tar -xvf valgrind-${valgrindversion}.tar.bz2
cd valgrind-${valgrindversion}

./autogen.sh
./configure --prefix=/tmp/vg
make -j3
make -j3 install
popd

export PATH=/tmp/vg/bin:$PATH
export B2_INCLUDE=/tmp/vg/include

. $(dirname "${BASH_SOURCE[0]}")/../build.sh
