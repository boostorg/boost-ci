#!/bin/bash

set -ex
echo ">>>>> APT: REPO.."
for i in {1..3}; do sudo -E apt-add-repository -y "ppa:ubuntu-toolchain-r/test" && break || sleep 10; done

if test -n "${LLVM_OS}" ; then
    wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add -
    if test -n "${LLVM_VER}" ; then
        sudo -E apt-add-repository "deb http://apt.llvm.org/${LLVM_OS}/ llvm-toolchain-${LLVM_OS}-${LLVM_VER} main"
    else
        # Snapshot (i.e. trunk) build of clang
        sudo -E apt-add-repository "deb http://apt.llvm.org/${LLVM_OS}/ llvm-toolchain-${LLVM_OS} main"
    fi
fi
echo ">>>>> APT: UPDATE.."
sudo -E apt-get -o Acquire::Retries=3 update
if test -n "${SOURCES}" ; then
    echo ">>>>> APT: INSTALL SOURCES.."
    for SOURCE in $SOURCES; do
        sudo -E apt-add-repository ppa:$SOURCE
    done
fi
echo ">>>>> APT: INSTALL ${PACKAGES}.."
sudo -E DEBIAN_FRONTEND=noninteractive apt-get -o Acquire::Retries=3 -y --no-install-suggests --no-install-recommends install ${PACKAGES}
