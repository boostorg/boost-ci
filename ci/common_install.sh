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
# - BOOST_CI_TARGET_BRANCH
# - BOOST_CI_SRC_FOLDER
# - GIT_FETCH_JOBS to fetch in parallel
# Will set:
# - BOOST_ROOT

set -ex

CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

. "$CI_DIR"/enforce.sh

if [ -z "$SELF" ]; then
    export SELF=$(python "$CI_DIR/get_libname.py")
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

DEPINST_ARGS=()
if [[ -n "$GIT_FETCH_JOBS" ]]; then
    DEPINST_ARGS+=("--git_args" "--jobs $GIT_FETCH_JOBS")
fi

python tools/boostdep/depinst/depinst.py --include benchmark --include example --include examples --include tools "${DEPINST_ARGS[@]}" $DEPINST $SELF

# Deduce B2_TOOLSET if unset from B2_COMPILER
if [ -z "$B2_TOOLSET" ] && [ -n "$B2_COMPILER" ]; then
    if [[ "$B2_COMPILER" =~ clang ]]; then
        B2_TOOLSET=clang
    elif [[ "$B2_COMPILER" =~ gcc|g\+\+ ]]; then
        B2_TOOLSET=gcc
    else
        echo "Unknown compiler: '$B2_COMPILER'. Need either clang or gcc/g++" >&2
        false
    fi
fi

if [[ "$B2_TOOLSET" == clang* ]]; then
    # If clang was installed from LLVM APT it will not have a /usr/bin/clang++
    # so we need to add the correctly versioned llvm bin path to the PATH
    if [ -f "/etc/debian_version" ]; then
        ver=""
        if [[ "$B2_TOOLSET" == clang-* ]]; then
            ver="${B2_TOOLSET#*-}"
        elif [[ "$B2_COMPILER" == clang-* ]] || [[ "$B2_COMPILER" == clang++-* ]]; then
            # Don't change path if we do find the versioned compiler
            if ! command -v $B2_COMPILER; then
                ver="${B2_COMPILER#*-}"
            fi
        else
            echo "Can't get clang version from B2_TOOLSET or B2_COMPILER. Skipping PATH setting." >&2
        fi
        if [[ -n "$ver" ]]; then
            export PATH="/usr/lib/llvm-${ver}/bin:$PATH"
            ls -ls /usr/lib/llvm-${ver}/bin || true
            hash -r || true
        fi
    elif [ -n "${XCODE_APP}" ]; then
        sudo xcode-select -switch ${XCODE_APP}
    fi
    command -v clang || true
    command -v clang++ || true

    # Additionally, if B2_TOOLSET is clang variant but CXX is set to g++
    # (it is on Linux images) then boost build silently ignores B2_TOOLSET and
    # uses CXX instead
    if [[ -n "$CXX" ]] && [[ "$CXX" != clang* ]]; then
        echo "CXX is set to $CXX in this environment which would override"
        echo "the setting of B2_TOOLSET=clang, therefore we clear CXX here."
        export CXX=
    fi
fi

# Set up user-config to actually use B2_COMPILER if set
if [ -n "$B2_COMPILER" ]; then
    # Get C++ compiler
    if [[ "$B2_COMPILER" == clang* ]] && [[ "$B2_COMPILER" != clang++* ]]; then
        CXX="${B2_COMPILER/clang/clang++}"
    else
        CXX="${B2_COMPILER/gcc/g++}"
    fi
    

    if ! command -v $CXX; then
        echo "Error: Compiler $CXX was not installed properly"
        exit 1
    fi
    echo "Compiler location: $(command -v $CXX)"
    echo "Compiler version: $($CXX --version)"
    export CXX

    echo -n "using $B2_TOOLSET : : $CXX" > ~/user-config.jam
    if [ -n "$GCC_TOOLCHAIN_ROOT" ]; then
        echo -n " : <compileflags>\"--gcc-toolchain=$GCC_TOOLCHAIN_ROOT\" <linkflags>\"--gcc-toolchain=$GCC_TOOLCHAIN_ROOT\"" >> ~/user-config.jam
    fi
    echo " ;" >> ~/user-config.jam
fi

function show_bootstrap_log
{
    cat bootstrap.log
}

if [[ "$B2_DONT_BOOTSTRAP" != "1" ]]; then
    trap show_bootstrap_log ERR
    ./bootstrap.sh
    trap - ERR
    ./b2 headers
fi
