#!/bin/bash
#
# Copyright 2021 Alexander Grund
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at
#      http://www.boost.org/LICENSE_1_0.txt)
#
# Bash script to run on Github to perform codecov.io integration
#

set -ex

source $(dirname "${BASH_SOURCE[0]}")/../codecov.sh "$1"

if [[ "$1" == "setup" ]]; then
    echo "B2_VARIANT=$B2_VARIANT" >> "$GITHUB_ENV"
    echo "B2_CXXFLAGS=$B2_CXXFLAGS" >> "$GITHUB_ENV"
    echo "B2_LINKFLAGS=$B2_LINKFLAGS" >> "$GITHUB_ENV"
fi
