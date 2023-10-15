#!/bin/bash

set -e

function add_repository {
    name="$1"
    echo -e "\tAdding repository $name"
    for i in {1..3}; do sudo -E apt-add-repository -y "$name" && return 0 || sleep 10; done
    return 1 # Failed
}

function add_repository_toolchain {
    name="$1"
    echo -e "\tAdding repository $name"
    # an alternative method, if apt-add-repository seems to be unresponsive
    VERSION_CODENAME=$(grep -ioP '^VERSION_CODENAME=\K.+' /etc/os-release || true)
    if [ -z $VERSION_CODENAME ]; then
        if grep -i trusty /etc/os-release; then
            VERSION_CODENAME=trusty
        elif grep -i precise /etc/os-release; then
            VERSION_CODENAME=precise
        fi
    fi
    echo "VERSION_CODENAME is ${VERSION_CODENAME}"
    echo "deb http://ppa.launchpad.net/ubuntu-toolchain-r/test/ubuntu ${VERSION_CODENAME} main" > /etc/apt/sources.list.d/ubuntu-toolchain-r-ubuntu-test-${VERSION_CODENAME}.list
    echo "# deb-src http://ppa.launchpad.net/ubuntu-toolchain-r/test/ubuntu ${VERSION_CODENAME} main" >> /etc/apt/sources.list.d/ubuntu-toolchain-r-ubuntu-test-${VERSION_CODENAME}.list
    curl -sSL --retry ${NET_RETRY_COUNT:-5} 'http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x1E9377A2BA9EF27F' | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/toolchain-r.gpg
}

echo ">>>>> APT: REPOSITORIES..."

if [ "$UBUNTU_TOOLCHAIN_DISABLE" != "true" ]; then
    # add_repository "ppa:ubuntu-toolchain-r/test"
    add_repository_toolchain "ppa:ubuntu-toolchain-r/test"
else
    echo "UBUNTU_TOOLCHAIN_DISABLE is 'true'. Not installing ppa:ubuntu-toolchain-r/test"
fi

if [ -n "${LLVM_OS}" ]; then
    echo ">>>>> APT: INSTALL LLVM repo"
    curl -sSL --retry 5 https://apt.llvm.org/llvm-snapshot.gpg.key | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/llvm-snapshot.gpg
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
