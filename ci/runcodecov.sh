#!/bin/bash

set -eu
# set -x

reponame=$1
echo "reponame is $reponame"
echo "date is $(date)"
mkdir -p /tmp/lcov-repo-results || true

# Filters.
# jump ahead to continue testing
if [[ "$reponame" =~ ${LCOV_SKIP_PATTERN} ]]; then
   echo "skipping ahead X letters"
elif [[ "$LCOV_SKIPLIST" =~ $reponame ]]; then
    echo "repo in skiplist"
else
    # required vars for codecov.sh:
    # BOOST_ROOT is already set
    BOOST_CI_SRC_FOLDER=$(pwd)
    export BOOST_CI_SRC_FOLDER
    if ! SELF=$(python3 "$CI_DIR/get_libname.py"); then
        echo "..failed to determine SELF name of lib"
        echo "$reponame failed to determine SELF variable. May be expected. Continuing." >> /tmp/failed.txt
        exit 0
    fi
    export SELF

    # clean disk space
    rm -rf "$BOOST_ROOT/bin.v2/libs"

    # Run the parts of travis/codecov.sh separately:
    # shellcheck disable=SC1091
    source "$CI_DIR"/codecov.sh "setup"
    set +e
    if ! "$CI_DIR"/build.sh ; then
        echo "..failed. CODECOV FAILED at build.sh. LIBRARY $reponame"
        echo "$reponame failed build.sh" >> /tmp/failed.txt
    fi
    echo "After build.sh"
    echo "Running codecov.sh collect"
    set -o pipefail
    if ! "$CI_DIR"/codecov.sh "collect" 2>&1 | tee "/tmp/lcov-repo-results/$reponame" ; then
        echo "..failed. CODECOV FAILED coverage. LIBRARY $reponame"
        echo "$reponame failed coverage" >> /tmp/failed.txt
    else
        echo "LIBRARY $reponame SUCCEEDED."
        echo "$reponame" >> /tmp/succeeded.txt
    fi

    echo "LIBRARY $reponame RESULTS:" >> /tmp/lcov-results.txt
    grep "lcov: ERROR" "/tmp/lcov-repo-results/$reponame" >> /tmp/lcov-results.txt || true
    grep "lcov: WARNING" "/tmp/lcov-repo-results/$reponame" >> /tmp/lcov-results.txt || true
fi
