#!/bin/bash

set -e

function add_repository {
    name="$1"
    echo -e "\tAdding repository $name"
    for i in {1..3}; do sudo -E apt-add-repository -y "$name" && return 0 || sleep 10; done
    return 1 # Failed
}

echo ">>>>> APT: REPOSITORIES..."

if [ "$UBUNTU_TOOLCHAIN_DISABLE" != "true" ]; then
    add_repository "ppa:ubuntu-toolchain-r/test"
else
    echo "UBUNTU_TOOLCHAIN_DISABLE is 'true'. Not installing ppa:ubuntu-toolchain-r/test"
fi

if [ -n "${LLVM_OS}" ]; then
    echo ">>>>> APT: INSTALL LLVM repo"
    curl -sSL --retry 5 https://apt.llvm.org/llvm-snapshot.gpg.key | sudo gpg --dearmor > /etc/apt/trusted.gpg.d/llvm-snapshot.gpg
    if [ -n "${LLVM_VER}" ]; then
        llvm_toolchain="llvm-toolchain-${LLVM_OS}-${LLVM_VER}"
    else
        # Snapshot (i.e. trunk) build
        llvm_toolchain="llvm-toolchain-${LLVM_OS}"
    fi
    add_repository "deb http://apt.llvm.org/${LLVM_OS}/ ${llvm_toolchain} main"
fi

if [ -n "${SOURCES}" ]; then
    echo ">>>>> APT: INSTALL PPAs from \$SOURCES..."
    for SOURCE in $SOURCES; do
        add_repository "ppa:$SOURCE"
    done
fi

echo ">>>>> APT: UPDATE..."
sudo -E apt-get -o Acquire::Retries=3 update

echo ">>>>> APT: INSTALL ${PACKAGES}..."
sudo -E DEBIAN_FRONTEND=noninteractive apt-get -o Acquire::Retries=3 -y --no-install-suggests --no-install-recommends install ${PACKAGES}
