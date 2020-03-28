#! /bin/bash
#
# Copyright 2017 - 2019 James E. King III
# Copyright 2019 Mateusz Loskot <mateusz at loskot dot net>
# Copyright 2020 Alexander Grund
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at
#      http://www.boost.org/LICENSE_1_0.txt)
#
# Executes the install phase
#
# If your repository has additional directories beyond
# "example", "examples", "tools", and "test" then you
# can add them in the environment variable DEPINST.
# i.e. - DEPINST="--include dirname1 --include dirname2"
#
# CI specific environment variables need to be set:
# - SELF
# - BOOST_CI_TARGET_BRANCH
# - BOOST_CI_SRC_FOLDER
# Will set:
# - BOOST_ROOT

set -ex

. $(dirname "${BASH_SOURCE[0]}")/enforce.sh

if [ "$SELF" == "interval" ]; then
    export SELF=numeric/interval
fi

# Handle also /refs/head/master
if [ "$BOOST_CI_TARGET_BRANCH" == "master" ] || [[ "$BOOST_CI_TARGET_BRANCH" == */master ]]; then
    export BOOST_BRANCH="master"
else
    export BOOST_BRANCH="develop"
fi

cd ..

git clone -b $BOOST_BRANCH --depth 1 https://github.com/boostorg/boost.git boost-root
cd boost-root
git submodule update -q --init tools/boostdep
mkdir -p libs/$SELF
cp -r $BOOST_CI_SRC_FOLDER/* libs/$SELF

export BOOST_ROOT="$(pwd)"
export PATH="$(pwd):$PATH"

python tools/boostdep/depinst/depinst.py --include benchmark --include example --include examples --include tools $DEPINST $SELF

# If clang was installed from LLVM APT it will not have a /usr/bin/clang++
# so we need to add the correctly versioned llvm bin path to the PATH
if [[ "$B2_TOOLSET" == clang-* ]]; then
    ver="${B2_TOOLSET#*-}"
    export PATH="/usr/lib/llvm-${ver}/bin:$PATH"
    ls -ls /usr/lib/llvm-${ver}/bin || true
    hash -r || true
    command -v clang || true
    command -v clang++ || true

    # Additionally, if B2_TOOLSET is clang variant but CXX is set to g++
    # (it is on Linux images) then boost build silently ignores B2_TOOLSET and
    # uses CXX instead
    if [[ "${CXX}" != clang* ]]; then
        echo "CXX is set to ${CXX} in this environment which would override"
        echo "the setting of B2_TOOLSET=clang, therefore we clear CXX here."
        export CXX=
    fi
fi

function show_bootstrap_log
{
    cat bootstrap.log
}

trap show_bootstrap_log ERR
./bootstrap.sh --with-toolset=${B2_TOOLSET%%-*}
trap - ERR
./b2 headers
