#!/bin/bash
#
# Copyright 2017 - 2019 James E. King III
# Copyright 2022 - 2026 Alexander Grund
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at
#      http://www.boost.org/LICENSE_1_0.txt)
#
# Bash script to perform a Coverity Scan build
# To skip the coverity integration download (which is huge) if
# you already have it from a previous run, add --skipdownload
#
# This is the shared implementation used by the CI specific wrappers
# ci/travis/coverity.sh and ci/github/coverity.sh.
#

#
# Environment Variables
#
# COVERITY_SCAN_NOTIFICATION_EMAIL  - email address to notify
# COVERITY_SCAN_TOKEN               - the Coverity Scan token (should be secure)
# BOOST_REPO                        - repo this is run on, e.g. boostorg/foo
# BOOST_BRANCH                      - target branch of PR or current branch
# SELF                              - the boost libs directory name
#
# Optional overrides:
#
# COVERITY_PROJECT                  - Coverity project to download for/upload to
#                                     (default: BOOST_REPO)
# COVERITY_VERSION                  - version reported to Coverity
#                                     (default: BOOST_BRANCH)
# COVERITY_DESCRIPTION              - description reported to Coverity
#                                     (default: COVERITY_PROJECT)
# COVERITY_COMPILER                 - compiler to configure Coverity for, e.g. clang++.
#                                     If set, cov-configure is run before the build.
# COVERITY_CLEAN_BUILD              - set to 0 to skip the "clean"-build
#                                     (default: 1)

set -eux

CI_DIR="$(dirname "${BASH_SOURCE[0]}")"

: "${COVERITY_PROJECT:=${BOOST_REPO:-}}"
: "${COVERITY_VERSION:=${BOOST_BRANCH:-}}"
: "${COVERITY_DESCRIPTION:=${COVERITY_PROJECT}}"
: "${COVERITY_CLEAN_BUILD:=1}"
RESULTS_DIR="cov-int"

pushd /tmp
if [[ "${1:-}" != "--skipdownload" ]]; then
  rm -rf coverity_tool.tgz cov-analysis*
  curl -L -d "token=$COVERITY_SCAN_TOKEN&project=$COVERITY_PROJECT" -X POST https://scan.coverity.com/download/cxx/linux64 -o coverity_tool.tgz
  tar xzf coverity_tool.tgz
fi
COVBIN=$(echo "$(pwd)"/cov-analysis*/bin)
export PATH=$COVBIN:$PATH
popd

if [[ "${COVERITY_CLEAN_BUILD}" == "1" ]]; then
  "$CI_DIR"/build.sh clean
fi
rm -rf "${RESULTS_DIR}"
mkdir -p "${RESULTS_DIR}"

if [[ -n "${COVERITY_COMPILER:-}" ]]; then
  cov-configure --template --compiler "${COVERITY_COMPILER}" --comptype "clangcxx"
  unset CXX
fi

cov-build --dir "${RESULTS_DIR}" "$CI_DIR"/build.sh

ls -ls "${RESULTS_DIR}"
tail -50 "${RESULTS_DIR}/build-log.txt"

COVERITY_ARCHIVE=cov-int.tar.cz
tar cJf "${COVERITY_ARCHIVE}" "${RESULTS_DIR}"

curl --form token="$COVERITY_SCAN_TOKEN" \
     --form email="$COVERITY_SCAN_NOTIFICATION_EMAIL" \
     --form file=@"${COVERITY_ARCHIVE}" \
     --form version="$COVERITY_VERSION" \
     --form description="$COVERITY_DESCRIPTION" \
     https://scan.coverity.com/builds?project="$COVERITY_PROJECT"
