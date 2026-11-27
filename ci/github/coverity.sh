#!/bin/bash
#
# Copyright 2017 - 2022 James E. King III
# Copyright 2022 - 2026 Alexander Grund
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
CXX=$(grep -F using ~/user-config.jam | head -1 | cut -d' ' -f5)

if [[ "${CXX}" != "clang"* ]]; then
  echo "GHA CI Coverity jobs only support clang toolsets right now."
  exit 1
fi

if [[ -z "${COVERITY_SCAN_TOKEN}" || -z "${COVERITY_SCAN_NOTIFICATION_EMAIL}" ]]; then
  echo "GHA CI Coverity jobs require COVERITY_SCAN_TOKEN and COVERITY_SCAN_NOTIFICATION_EMAIL secrets."
  exit 1
fi

export BOOST_REPO="${GITHUB_REPOSITORY}"
export BOOST_BRANCH="${GITHUB_REF_NAME}"
export COVERITY_DESCRIPTION="${GITHUB_REPOSITORY}:${GITHUB_REF}:${GITHUB_SHA}:${GITHUB_RUN_NUMBER}"
export COVERITY_COMPILER="${CXX}"
export COVERITY_CLEAN_BUILD=0

"$(dirname "${BASH_SOURCE[0]}")"/../coverity.sh "$@"
