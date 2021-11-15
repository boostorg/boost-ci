#! /bin/bash
#
# Copyright 2017 - 2019 James E. King III
# Copyright 2021 Alexander Grund
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at
#      http://www.boost.org/LICENSE_1_0.txt)
#
# Bash script to run in travis to perform codecov.io integration
#

set -ex

CI_DIR="$(dirname "${BASH_SOURCE[0]}")/.."

source "$CI_DIR"/codecov.sh "setup"
"$CI_DIR"/build.sh
"$CI_DIR"/codecov.sh "upload"
