#!/bin/bash

set -eu
# set -x

export LCOV_SKIPLIST="math"

: "${LCOV_SKIP_PATTERN:='^[9]'}" # Set default lcov skip pattern

pwd

export CI_DIR=${BOOST_CI_SRC_FOLDER}/ci
export LCOV_VERSION="v2.3"
export LCOV_IGNORE_ERRORS_LEVEL=standard

touch /tmp/failed.txt
touch /tmp/succeeded.txt

cd "$BOOST_ROOT"
git submodule update --init --recursive --jobs 4
./b2 headers

# shellcheck disable=SC2016
git submodule foreach '$CI_DIR/runcodecov.sh $name'

echo " "
echo "The following is a collection of all lcov warnings/errors"
echo " "
cat /tmp/lcov-results.txt
echo " "
echo "The above list is a collection of all lcov warnings/errors"
echo " "

echo " "
echo "The following is a collection of less usual lcov warnings/errors"
echo " "
grep -v mismatch /tmp/lcov-results.txt | grep -v inconsistent | grep -v unused
echo " "
echo "The above list is a collection of less usual lcov warnings/errors"
echo " "


failed=$(wc -l /tmp/failed.txt | cut -d" " -f1)
succeeded=$(wc -l /tmp/succeeded.txt | cut -d" " -f1)
echo "$failed failed, $succeeded succeeded."
echo ""
cat /tmp/failed.txt

sleep 60

echo "Completed"
