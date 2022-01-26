#! /bin/bash
#
# Copyright 2017 - 2022 James E. King III
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at
#      http://www.boost.org/LICENSE_1_0.txt)
#
# Bash script to run in GHA to perform a Coverity Scan build
# Environment Variables you must define (as secrets in GHA):
#
# COVERITY_SCAN_NOTIFICATION_EMAIL  - email address to notify
# COVERITY_SCAN_TOKEN               - the Coverity Scan token (should be secure)
#

set -ex

# install.sh will call common_install.sh in a previous CI step and write CXX 
# out to a file but it isn't available in subsequent CI steps, so pick it up
CXX=$(cat ~/user-config.jam | cut -d' ' -f5)

if [[ "${CXX}" != "clang"* ]]; then
  echo "GHA CI Coverity jobs only support clang toolsets right now."
  exit 1
fi

if [[ -z "${COVERITY_SCAN_TOKEN}" || -z "${COVERITY_SCAN_NOTIFICATION_EMAIL}" ]]; then
  echo "GHA CI Coverity jobs require COVERITY_SCAN_TOKEN and COVERITY_SCAN_NOTIFICATION_EMAIL secrets."
  exit 1
fi

sudo wget -nv https://entrust.com/root-certificates/entrust_l1k.cer -O /tmp/scanca.cer

pushd /tmp
rm -rf coverity_tool.tgz cov-analysis*
curl --cacert /tmp/scanca.cer -L -d "token=${COVERITY_SCAN_TOKEN}&project=${GITHUB_REPOSITORY}" -X POST https://scan.coverity.com/download/cxx/linux64 -o coverity_tool.tgz
tar xzf coverity_tool.tgz
COVBIN=$(echo $(pwd)/cov-analysis*/bin)
export PATH=${COVBIN}:${PATH}
popd

RESULTS_DIR="$(pwd)/cov-int"
mkdir "${RESULTS_DIR}"
cov-configure --template --compiler "${CXX}" --comptype "clangcxx"
unset CXX

cov-build --dir "${RESULTS_DIR}" ci/build.sh

ls -ls "${RESULTS_DIR}"
tail -50 "${RESULTS_DIR}/build-log.txt"
tar czf cov-int.tgz cov-int
curl --cacert /tmp/scanca.cer \
     --form token="${COVERITY_SCAN_TOKEN}" \
     --form email="${COVERITY_SCAN_NOTIFICATION_EMAIL}" \
     --form file=@cov-int.tgz \
     --form version="${GITHUB_REF_NAME}" \
     --form description="${GITHUB_REPOSITORY}:${GITHUB_REF}:${GITHUB_SHA}:${GITHUB_RUN_NUMBER}" \
     https://scan.coverity.com/builds?project="${GITHUB_REPOSITORY}"
