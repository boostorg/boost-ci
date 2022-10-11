#! /bin/bash
#
# Copyright 2017 - 2019 James E. King III
# Copyright 2019 Mateusz Loskot <mateusz at loskot dot net>
# Copyright 2021 Alexander Grund
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at
#      http://www.boost.org/LICENSE_1_0.txt)
#
# Executes the install phase for Azure Pipelines (AzP)
#
#
# If your repository has additional directories beyond
# "example", "examples", "tools", and "test" then you
# can add them in the environment variable DEPINST.
# i.e. - DEPINST="--include dirname1 --include dirname2"
#
# To install packages set PACKAGES and optionally LLVM_REPO

set -ex

function get_compiler_package {
    local result="$1"
    result="${result/gcc-/g++-}"
    result="${result/clang++-/clang-}"
    echo "$result"
}

if [ "$AGENT_OS" == "Darwin" ]; then
    unset -f cd
fi

# CI builds set BUILD_SOURCEBRANCHNAME
# Pull request builds set SYSTEM_PULLREQUEST_TARGETBRANCH.
export BOOST_CI_TARGET_BRANCH="${SYSTEM_PULLREQUEST_TARGETBRANCH:-$BUILD_SOURCEBRANCHNAME}"
export BOOST_CI_SRC_FOLDER="$BUILD_SOURCESDIRECTORY"

if [ -z "$B2_COMPILER" ]; then
    export B2_COMPILER="$CXX"
fi

if [ "$AGENT_OS" != "Darwin" ]; then
    # If no package set install at least the compiler if not already found
    if [[ -z "$PACKAGES" ]] && ! command -v $B2_COMPILER; then
        PACKAGES="$(get_compiler_package "$B2_COMPILER")"
    fi

    if [ -n "$PACKAGES" ]; then
        for i in {1..${NET_RETRY_COUNT:-3}}; do
            sudo -E apt-add-repository -y "ppa:ubuntu-toolchain-r/test" && break || sleep 10
        done
        if [ -n "${LLVM_REPO}" ]; then
            curl -sSL --retry ${NET_RETRY_COUNT:-5} https://apt.llvm.org/llvm-snapshot.gpg.key | sudo gpg --dearmor > /etc/apt/trusted.gpg.d/llvm-snapshot.gpg
            for i in {1..${NET_RETRY_COUNT:-3}}; do 
                sudo -E apt-add-repository "deb http://apt.llvm.org/${LLVM_OS:-xenial}/ ${LLVM_REPO} main" && break || sleep 10
            done
        fi
        sudo apt-get ${NET_RETRY_COUNT:+ -o Acquire::Retries=$NET_RETRY_COUNT} update
        sudo apt-get ${NET_RETRY_COUNT:+ -o Acquire::Retries=$NET_RETRY_COUNT} install -y ${PACKAGES}
    fi
fi

old_B2_TOOLSET="$B2_TOOLSET"

. $(dirname "${BASH_SOURCE[0]}")/../common_install.sh

# AzP requires to run special task in order to export job-scoped variable from a script.
#
# NOTE: The set +x is required! See the troubleshooting guide:
# https://docs.microsoft.com/en-us/azure/devops/pipelines/troubleshooting#variables-having--single-quote-appended

set +x
echo "##vso[task.setvariable variable=SELF]$SELF"
echo "##vso[task.setvariable variable=BOOST_ROOT]$BOOST_ROOT"
[ -n "old_B2_TOOLSET" ] || echo "##vso[task.setvariable variable=B2_TOOLSET]$B2_TOOLSET"
echo "##vso[task.setvariable variable=B2_COMPILER]$B2_COMPILER"
set -x
