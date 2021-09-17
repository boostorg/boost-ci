#! /bin/bash
#
# Copyright 2017 - 2019 James E. King III
# Copyright 2019 Mateusz Loskot <mateusz at loskot dot net>
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

if [ "$AGENT_OS" == "Darwin" ]; then
    unset -f cd
fi

LLVM_OS=${LLVM_OS:-xenial}

if [ -n "$PACKAGES" ]; then
	sudo -E apt-add-repository -y "ppa:ubuntu-toolchain-r/test"
	if [ -n "${LLVM_REPO}" ]; then
	  wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add -
	  sudo -E apt-add-repository "deb http://apt.llvm.org/${LLVM_OS}/ ${LLVM_REPO} main"
	fi
	sudo -E apt-get update
	sudo -E apt-get -yq --no-install-suggests --no-install-recommends install ${PACKAGES}
fi

if [ -n "${XCODE_APP}" ]; then
    sudo xcode-select -switch ${XCODE_APP}
	which clang++
fi

# AzP does not clone into folder named after repository,
# but into one named something like /home/vsts/work/1/s
# SELF needs to be derived from the name of the repository
# that this build is configured for.
export SELF=`basename $BUILD_REPOSITORY_NAME`

# CI builds set BUILD_SOURCEBRANCHNAME
# Pull request builds set SYSTEM_PULLREQUEST_TARGETBRANCH.
export BOOST_CI_TARGET_BRANCH="${SYSTEM_PULLREQUEST_TARGETBRANCH:-$BUILD_SOURCEBRANCHNAME}"
export BOOST_CI_SRC_FOLDER="$BUILD_SOURCESDIRECTORY"

. $(dirname "${BASH_SOURCE[0]}")/../common_install.sh

# AzP official images of Ubuntu 16.04 behave differently to Travis CI.
# The gcc and clang variants are being installed somewhat weirdly
# and, unlike on linux images on Travis CI, b2 fails with:
#
# /home/vsts/work/1/s/boost-root/tools/build/src/tools/gcc.jam:230: in gcc.init from module gcc
# error: toolset gcc initialization:
# error: no command provided, default command 'g++' not found
# error: initialized from ../../project-config.jam:12
#
# Hence, we work around this issue with user-config.jam
if ! command -v ${CXX}; then
    echo "WARNING: Compiler ${CXX} was not installed properly"
    #exit 1
fi
echo "using ${B2_TOOLSET} : : $(command -v ${CXX}) : ${B2_CXXFLAGS} ;" > ${HOME}/user-config.jam

# AzP requires to run special task in order to export job-scoped variable from a script.
#
# NOTE: The set +x is required! See the troubleshooting guide:
# https://docs.microsoft.com/en-us/azure/devops/pipelines/troubleshooting#variables-having--single-quote-appended

set +x
echo "##vso[task.setvariable variable=SELF]$SELF"
echo "##vso[task.setvariable variable=BOOST_ROOT]$BOOST_ROOT"
set -x
