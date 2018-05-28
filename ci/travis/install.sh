#! /bin/bash
#
# Copyright 2017, 2018 James E. King III
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at
#      http://www.boost.org/LICENSE_1_0.txt)
#
# Executes the install phase for travis
#

set -ex

cd ..
git clone -b $TRAVIS_BRANCH --depth 1 https://github.com/boostorg/boost.git boost-root
cd boost-root
git submodule update -q --init tools/boostdep
git submodule update -q --init tools/build
git submodule update -q --init tools/inspect
cp -r $TRAVIS_BUILD_DIR/* libs/$SELF
export BOOST_ROOT="`pwd`"
export PATH="`pwd`":$PATH
python tools/boostdep/depinst/depinst.py --include example --include examples --include tools $SELF
./bootstrap.sh
./b2 headers

