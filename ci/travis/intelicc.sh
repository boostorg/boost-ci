#! /bin/bash
#
# Copyright 2018 James E. King III
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at
#      http://www.boost.org/LICENSE_1_0.txt)
#
# Bash script to install Intel ICC.
#

#
# Environment Variables
#
# INTEL_ICC_SERIAL_NUMBER           - the Intel ICC serial number to use
# SELF                              - the boost libs directory name
# B2_TOOLSET                        - the toolset to use (intel-linux)

set -ex

. $(dirname "${BASH_SOURCE[0]}")/enforce.sh

function finish {
  rm -rf /tmp/parallel_studio_xe_2019_update1_professional_edition_for_cpp_online/silent.cfg
}

pushd /tmp
wget --quiet http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/14857/parallel_studio_xe_2019_update1_professional_edition_for_cpp_online.tgz
tar xzf parallel_studio_xe_2019_update1_professional_edition_for_cpp_online.tgz
cd parallel_studio_xe_2019_update1_professional_edition_for_cpp_online/
trap finish EXIT
cat << EOF > silent.cfg
ACCEPT_EULA=accept
CONTINUE_WITH_OPTIONAL_ERROR=yes
PSET_INSTALL_DIR=/opt/intel
CONTINUE_WITH_INSTALLDIR_OVERWRITE=yes
PSET_MODE=install
ACTIVATION_SERIAL_NUMBER=$INTEL_ICC_SERIAL_NUMBER
ACTIVATION_TYPE=serial_number
AMPLIFIER_SAMPLING_DRIVER_INSTALL_TYPE=kit
AMPLIFIER_DRIVER_ACCESS_GROUP=vtune
AMPLIFIER_DRIVER_PERMISSIONS=666
AMPLIFIER_LOAD_DRIVER=no
AMPLIFIER_C_COMPILER=/usr/bin/gcc
AMPLIFIER_MAKE_COMMAND=/usr/bin/make
AMPLIFIER_INSTALL_BOOT_SCRIPT=no
AMPLIFIER_DRIVER_PER_USER_MODE=no
INTEL_SW_IMPROVEMENT_PROGRAM_CONSENT=no
ARCH_SELECTED=ALL
COMPONENTS=;intel-conda-index-tool__x86_64;intel-comp__x86_64;intel-comp-32bit__x86_64;intel-comp-doc__noarch;intel-comp-l-all-common__noarch;intel-comp-l-all-vars__noarch;intel-comp-nomcu-vars__noarch;intel-comp-ps-32bit__x86_64;intel-comp-ps__x86_64;intel-comp-ps-ss__x86_64;intel-comp-ps-ss-bec__x86_64;intel-comp-ps-ss-bec-32bit__x86_64;intel-openmp__x86_64;intel-openmp-32bit__x86_64;intel-openmp-common__noarch;intel-openmp-common-icc__noarch;intel-tbb-libs-32bit__x86_64;intel-tbb-libs__x86_64;intel-idesupport-icc-common-ps__noarch;intel-conda-icc_rt-linux-64-shadow-package__x86_64;intel-icc__x86_64;intel-icc-32bit__x86_64;intel-c-comp-common__noarch;intel-icc-common__noarch;intel-icc-common-ps__noarch;intel-icc-common-ps-ss-bec__noarch;intel-icc-doc__noarch;intel-icc-doc-ps__noarch;intel-icc-ps__x86_64;intel-icc-ps-ss-bec__x86_64;intel-icc-ps-ss-bec-32bit__x86_64;intel-tbb-devel-32bit__x86_64;intel-tbb-devel__x86_64;intel-tbb-common__noarch;intel-tbb-doc__noarch;intel-conda-tbb-linux-64-shadow-package__x86_64;intel-conda-tbb-linux-32-shadow-package__x86_64;intel-conda-tbb-devel-linux-64-shadow-package__x86_64;intel-conda-tbb-devel-linux-32-shadow-package__x86_64;intel-ism__noarch;intel-ipsc__noarch;intel-psxe-common__noarch;intel-psxe-doc__noarch;intel-psxe-common-doc__noarch;intel-ips-doc__noarch;intel-psxe-licensing__noarch;intel-psxe-licensing-doc__noarch;intel-icsxe-pset
EOF
cat silent.cfg
sudo ./install.sh -s silent.cfg
rm -f silent.cfg
export PATH=/opt/intel/bin:$PATH
popd
cd ../..
./bootstrap.sh --with-toolset=$B2_TOOLSET
cd libs/$SELF
ci/travis/build.sh

