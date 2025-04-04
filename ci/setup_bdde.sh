#!/bin/bash
#
# Copyright 2024 Alexander Grund
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at
#      http://www.boost.org/LICENSE_1_0.txt)
#
# Setup the Boost Docker Development Environment (BDDE)
#
# The BDDE project at https://github.com/jeking3/bdde includes
# build containers for different operating systems and architectures
# using multiarch containers.
# This allows e.g. building in a big-endian environment on CI
# Simply set $BDDE_DISTRO, $BDDE_EDITION & $BDDE_ARCH
# and run your commands with the prefix `bdde`, e.g. `bdde true`
#
# Requires a Linux environment with root/sudo privileges

set -ex

if [ -f "/etc/debian_version" ]; then
    sudo apt-get -o Acquire::Retries="${NET_RETRY_COUNT:-3}" -y -q --no-install-suggests --no-install-recommends install binfmt-support qemu-user-static
fi

git clone --depth=1 https://github.com/jeking3/bdde.git

BDDE_SCRIPTS=$(pwd)/bdde/bin/linux

# this prepares the VM for multiarch docker
sudo ${BDDE_SCRIPTS}/bdde-multiarch
sudo ${BDDE_SCRIPTS}/bdde-multiarch --version

export PATH="${BDDE_SCRIPTS}:${PATH}"
