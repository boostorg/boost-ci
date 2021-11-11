#! /bin/bash
#
# Copyright 2017 - 2019 James E. King III
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at
#      http://www.boost.org/LICENSE_1_0.txt)
#
# Bash script to run in travis to perform codecov.io integration
#

set -ex

$(dirname "${BASH_SOURCE[0]}")/../codecov.sh "collect"
$(dirname "${BASH_SOURCE[0]}")/../codecov.sh "upload"
