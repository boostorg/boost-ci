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
    # If no package set install at least the compiler
    if [[ -z "$PACKAGES" ]]; then
        PACKAGES="$(get_compiler_package "$B2_COMPILER")"
    fi

    LLVM_OS=${LLVM_OS:-xenial}
    if [ -n "$PACKAGES" ]; then
        sudo -E apt-add-repository -y "ppa:ubuntu-toolchain-r/test"
        if [ -n "${LLVM_REPO}" ]; then
            wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add -
            sudo -E apt-add-repository "deb http://apt.llvm.org/${LLVM_OS}/ ${LLVM_REPO} main"
        fi
        sudo apt-get ${NET_RETRY_COUNT:+ -o Acquire::Retries=$NET_RETRY_COUNT} update
        sudo apt-get ${NET_RETRY_COUNT:+ -o Acquire::Retries=$NET_RETRY_COUNT} install -y ${PACKAGES}
    fi
elif [ -n "${XCODE_APP}" ]; then
    sudo xcode-select -switch ${XCODE_APP}
    which clang++
fi

. $(dirname "${BASH_SOURCE[0]}")/../common_install.sh

# AzP requires to run special task in order to export job-scoped variable from a script.
#
# NOTE: The set +x is required! See the troubleshooting guide:
# https://docs.microsoft.com/en-us/azure/devops/pipelines/troubleshooting#variables-having--single-quote-appended

set +x
echo "##vso[task.setvariable variable=SELF]$SELF"
echo "##vso[task.setvariable variable=BOOST_ROOT]$BOOST_ROOT"
echo "##vso[task.setvariable variable=B2_TOOLSET]$B2_TOOLSET"
echo "##vso[task.setvariable variable=B2_COMPILER]$B2_COMPILER"
set -x
