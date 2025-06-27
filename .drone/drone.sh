#!/bin/bash

# Copyright 2020 Rene Rivera, Sam Darwin
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE.txt or copy at http://boost.org/LICENSE_1_0.txt)

set -e

export USER=$(whoami)
export CC=${CC:-gcc}
export PATH=~/.local/bin:/usr/local/bin:$PATH

git clone https://github.com/boostorg/boost-ci.git boost-ci-cloned --depth 1
[ "$(basename $DRONE_REPO)" == "boost-ci" ] || cp -prf boost-ci-cloned/ci .
rm -rf boost-ci-cloned

export BOOST_CI_TARGET_BRANCH="$DRONE_BRANCH"
export BOOST_CI_SRC_FOLDER=$(pwd)
export CODECOV_NAME=${CODECOV_NAME:-"Drone CI"}

set +x
echo '==================================> INSTALL'

if [[ $(uname) == "Linux" ]]; then
    error=0
    if ! { echo 0 | sudo tee /proc/sys/kernel/randomize_va_space > /dev/null; } && [[ -n ${B2_ASAN:-} ]]; then
        echo -e "\n\nWARNING: Failed to disable KASLR. ASAN might fail with 'DEADLYSIGNAL'."
        error=1
    fi
    # sysctl just ignores some failures and does't return an error, only output
    if { ! out=$(sudo sysctl vm.mmap_rnd_bits=28 2>&1) || [[ "$out" == *"ignoring:"* ]]; } && [[ -n ${B2_TSAN:-} ]]; then
        echo -e "\n\nWARNING: Failed to change KASLR. TSAN might fail with 'FATAL: ThreadSanitizer: unexpected memory mapping'."
        error=1
    fi
    if ((error == 1)); then
        [[ "${DRONE_EXTRA_PRIVILEGED:-0}" == "True" ]] || echo 'Try passing `privileged=True` to the job in .drone.star'
        echo -e "\n"
    fi
fi

scripts=(
    "$BOOST_CI_SRC_FOLDER/.drone/before-install.sh"
    "$BOOST_CI_SRC_FOLDER/ci/common_install.sh"
    "$BOOST_CI_SRC_FOLDER/.drone/after-install.sh"
)
for script in "${scripts[@]}"; do
    if [ -e "$script" ]; then
        echo "==============================> RUN $script"
        source "$script"
        set +x
    fi
done

echo "B2 config: $(env | grep B2_ || true)"
echo "==================================> SCRIPT ($DRONE_JOB_BUILDTYPE)"

case "$DRONE_JOB_BUILDTYPE" in
    b2-ci-version-report)
        $BOOST_CI_SRC_FOLDER/.drone/b2-ci-version-report.sh
        ;;
    lcov-report)
        $BOOST_CI_SRC_FOLDER/.drone/lcov-report.sh
        ;;
    boost)
        $BOOST_CI_SRC_FOLDER/ci/build.sh
        ;;
    codecov)
        $BOOST_CI_SRC_FOLDER/ci/travis/codecov.sh
        ;;
    valgrind)
        $BOOST_CI_SRC_FOLDER/ci/travis/valgrind.sh
        ;;
    coverity)
        echo "DRONE_BRANCH=$DRONE_BRANCH, DRONE_BUILD_EVENT=$DRONE_BUILD_EVENT, DRONE_REPO=$DRONE_REPO"
        if [[ "$DRONE_BRANCH" =~ ^(master|develop)$ ]] && [[ "$DRONE_BUILD_EVENT" =~ ^(push|cron)$ ]]; then
            if [ -z "$COVERITY_SCAN_NOTIFICATION_EMAIL" ] || [ -z "$COVERITY_SCAN_TOKEN" ]; then
                echo "Coverity details not set up"
                [ -n "$COVERITY_SCAN_NOTIFICATION_EMAIL" ] || echo 'Missing $COVERITY_SCAN_NOTIFICATION_EMAIL'
                [ -n "$COVERITY_SCAN_TOKEN" ] || echo 'Missing $COVERITY_SCAN_TOKEN'
                exit 1
            fi
            export BOOST_REPO="$DRONE_REPO"
			export BOOST_BRANCH="$DRONE_BRANCH"
            $BOOST_CI_SRC_FOLDER/ci/coverity.sh
        fi
        ;;
    *)
        echo "Unknown build type: $DRONE_JOB_BUILDTYPE"
        ;;
esac
