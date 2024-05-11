#! /bin/bash
#
# Copyright 2017 - 2019 James E. King III
# Copyright 2022 - 2024 Alexander Grund
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
# BOOST_REPO                        - repo this is run on, e.g. boostorg/foo
# BOOST_BRANCH                      - target branch of PR or current branch
# SELF                              - the boost libs directory name

set -eux

CI_DIR="$(dirname "${BASH_SOURCE[0]}")"

pushd /tmp
if [[ "$1" != "--skipdownload" ]]; then
  rm -rf coverity_tool.tgz cov-analysis*
  curl -L -d "token=$COVERITY_SCAN_TOKEN&project=$BOOST_REPO" -X POST https://scan.coverity.com/download/cxx/linux64 -o coverity_tool.tgz
  tar xzf coverity_tool.tgz
fi
COVBIN=$(echo $(pwd)/cov-analysis*/bin)
export PATH=$COVBIN:$PATH
popd

"$CI_DIR"/build.sh clean
rm -rf cov-int/
cov-build --dir cov-int "$CI_DIR"/build.sh
tail -50 cov-int/build-log.txt
tar cJf cov-int.tar.xz cov-int/
curl --form token="$COVERITY_SCAN_TOKEN" \
     --form email="$COVERITY_SCAN_NOTIFICATION_EMAIL" \
     --form file=@cov-int.tar.xz \
     --form version="$BOOST_BRANCH" \
     --form description="$BOOST_REPO" \
     https://scan.coverity.com/builds?project="$BOOST_REPO"
