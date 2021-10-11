#! /bin/bash
#
# Copyright 2017 - 2019 James E. King III
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at
#      http://www.boost.org/LICENSE_1_0.txt)
#
# Bash script to run in travis to perform a bjam build
# cwd should be $BOOST_ROOT/libs/$SELF before running
#

set -ex

: ${B2_TARGETS:="libs/$SELF/test"}

. "$(dirname "${BASH_SOURCE[0]}")"/enforce.sh

export UBSAN_OPTIONS=print_stacktrace=1

cd "$BOOST_ROOT"

./b2 ${B2_TARGETS} "${B2_ARGS[@]}" "$@"
