#!/bin/bash
#
# Copyright 2017 - 2019 James E. King III
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at
#      http://www.boost.org/LICENSE_1_0.txt)
#
# Bash script to run in travis to perform a Coverity Scan build
# To skip the coverity integration download (which is huge) if
# you already have it from a previous run, add --skipdownload
#

#
# Environment Variables
#
# COVERITY_SCAN_NOTIFICATION_EMAIL  - email address to notify
# COVERITY_SCAN_TOKEN               - the Coverity Scan token (should be secure)
# SELF                              - the boost libs directory name

export BOOST_REPO="$TRAVIS_REPO_SLUG"
export BOOST_BRANCH="${BOOST_BRANCH:-$TRAVIS_BRANCH}"

"$(dirname "${BASH_SOURCE[0]}")/../coverity.sh"
