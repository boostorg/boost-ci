#!/bin/bash
#
# Copyright 2017 - 2022 James E. King III
# Copyright 2021-2024 Alexander Grund
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at
#      http://www.boost.org/LICENSE_1_0.txt)
#
# Bash script to to perform codecov.io integration
#

# Same requirements as build.sh
# Requires env vars:
# - BOOST_CI_SRC_FOLDER
# - BOOST_ROOT
# - SELF
# Call with either "setup", "collect" or "upload" as parameter

#
# If you want to exclude content from the coverage report you must check in
# a .codecov.yml file as is found in the boost-ci project, and it must be
# in the default branch for the repository.  It will not be picked up from
# a pull request.
#

set -eux

. "$(dirname "${BASH_SOURCE[0]}")"/enforce.sh

coverage_action=${1:-'<unset>'}

if [[ "$coverage_action" == "setup" ]]; then
    if [[ ${B2_CI_VERSION:-0} -eq 0 ]]; then
        # Old CI version needs to use the prefixes
        export B2_VARIANT="variant=debug"
        export B2_CXXFLAGS="${B2_CXXFLAGS:+$B2_CXXFLAGS }cxxflags=-fkeep-static-functions cxxflags=--coverage"
        export B2_LINKFLAGS="${B2_LINKFLAGS:+$B2_LINKFLAGS } linkflags=--coverage"
    else
        export B2_VARIANT=debug
        export B2_CXXFLAGS="${B2_CXXFLAGS:+$B2_CXXFLAGS }-fkeep-static-functions --coverage"
        export B2_LINKFLAGS="${B2_LINKFLAGS:+$B2_LINKFLAGS }--coverage"
    fi

elif [[ "$coverage_action" == "collect" ]] || [[ "$coverage_action" == "upload" ]]; then
    if [ -z "${GCOV:-}" ]; then
        ver=7 # default
        if [ "${B2_TOOLSET%%-*}" == "gcc" ]; then
            if [[ "$B2_TOOLSET" =~ gcc- ]]; then
                ver="${B2_TOOLSET##*gcc-}"
            elif [[ "$B2_COMPILER" =~ gcc- ]]; then
                ver="${B2_COMPILER##*gcc-}"
            fi
        fi
        GCOV=gcov-${ver}
    fi

    : "${LCOV_VERSION:=v2.3}" # Set default lcov version to install
    : "${LCOV_OPTIONS:=}"

    : "${LCOV_BRANCH_COVERAGE:=1}" # Set default for branch coverage

    : "${LCOV_IGNORE_ERRORS_LEVEL:="standard"}" # Set default error level. See below.

    case $LCOV_IGNORE_ERRORS_LEVEL in
    off)
        # All errors are potentially fatal.
        lcov_errors_to_ignore="";;
    minimal)
        # A suggested minimum even when trying to catch errors.
        lcov_errors_to_ignore="unused";;
    all)
        # ignore all lcov errors
        lcov_errors_to_ignore="annotate,branch,callback,category,child,count,corrupt,deprecated,empty,excessive,fork,format,inconsistent,internal,mismatch,missing,negative,package,parallel,path,range,source,unmapped,unsupported,unused,usage,utility,version";;
    standard)
        # A recommended default.
        # The majority of boost libraries should pass.
        # Notes about this setting:
        # inconsistent - This error indicates that your coverage data is internally inconsistent: it makes two or more mutually exclusive claims.
        # mismatch - Incorrect or inconsistent information found in coverage data and/or source code - for example, the source code contains overlapping exclusion directives.
        # unused - The include/exclude/erase/substitute/omit pattern did not match any file pathnames.
        #
        lcov_errors_to_ignore="inconsistent,mismatch,unused";;
    *)
        echo "The value of LCOV_IGNORE_ERRORS_LEVEL ($LCOV_IGNORE_ERRORS_LEVEL) is not recognized."
        echo "Please correct this. Exiting."
        exit 1
    esac

    if [ -n "${lcov_errors_to_ignore}" ]; then
        lcov_ignore_errors_flag="--ignore-errors ${lcov_errors_to_ignore}"
    else
        lcov_ignore_errors_flag=""
    fi

    # The four LEVELs for error suppression above are meant to cover the most common cases.
    # You can still select a fully custom option by using $LCOV_OPTIONS (in which case you may set $LCOV_IGNORE_ERRORS_LEVEL=off).

    if [[ "$LCOV_VERSION" =~ ^v1 ]]; then
        LCOV_OPTIONS="${LCOV_OPTIONS} --rc lcov_branch_coverage=${LCOV_BRANCH_COVERAGE}"

    elif [[ "$LCOV_VERSION" =~ ^v[2-9] ]]; then
        sudo apt-get -o Acquire::Retries="${NET_RETRY_COUNT:-3}" -y -q --no-install-suggests --no-install-recommends install \
            libcapture-tiny-perl libdatetime-perl libjson-xs-perl || true
            # libcpanel-json-xs-perl
        LCOV_OPTIONS="${LCOV_OPTIONS} --rc branch_coverage=${LCOV_BRANCH_COVERAGE} ${lcov_ignore_errors_flag}"
    fi

    # Remove extra whitespace
    LCOV_OPTIONS=$(echo ${LCOV_OPTIONS} | xargs echo)

    rm -rf /tmp/lcov
    cd /tmp
    git clone --depth 1 -b "${LCOV_VERSION}" https://github.com/linux-test-project/lcov.git
    export PATH=/tmp/lcov/bin:$PATH
    command -v lcov
    lcov --version

    # switch back to the original source code directory
    cd "$BOOST_CI_SRC_FOLDER"

    # coverage files are in ../../b2 from this location
    lcov ${LCOV_OPTIONS} --gcov-tool="$GCOV" --directory "$BOOST_ROOT" --capture --output-file all.info
    # dump a summary on the console
    lcov ${LCOV_OPTIONS} --list all.info

    # all.info contains all the coverage info for all projects - limit to ours
    # first we extract the interesting headers for our project then we use that list to extract the right things
    for f in $(for h in include/boost/*; do echo "$h"; done | cut -f2- -d/); do echo "*/$f*"; done > /tmp/interesting
    echo headers that matter:
    cat /tmp/interesting
    xargs --verbose -L 999999 -a /tmp/interesting lcov ${LCOV_OPTIONS} --extract all.info "*/libs/$SELF/*" --output-file coverage.info

    # dump a summary on the console - helps us identify problems in pathing
    # note this has test file coverage in it - if you do not want to count test
    # files against your coverage numbers then use a .codecov.yml file which
    # must be checked into the default branch (it is not read or used from a
    # pull request)
    lcov ${LCOV_OPTIONS} --list coverage.info

    if [[ "$coverage_action" == "upload" ]] && [[ "${BOOST_CI_CODECOV_IO_UPLOAD:-}" != "skip" ]]; then
        #
        # upload to codecov.io
        #
        curl -Os https://uploader.codecov.io/latest/linux/codecov

        # Verify Download
        if command -v gpg &> /dev/null && command -v gpgv &> /dev/null; then
            curl https://keybase.io/codecovsecurity/pgp_keys.asc | gpg --no-default-keyring --keyring trustedkeys.gpg --import

            curl -Os https://uploader.codecov.io/latest/linux/codecov.SHA256SUM
            curl -Os https://uploader.codecov.io/latest/linux/codecov.SHA256SUM.sig

            gpgv codecov.SHA256SUM.sig codecov.SHA256SUM
            shasum -a 256 -c codecov.SHA256SUM
        fi

        chmod +x codecov
        ./codecov --verbose --nonZero ${CODECOV_NAME:+--name "$CODECOV_NAME"} ${CODECOV_TOKEN:+--token "$CODECOV_TOKEN"} -f coverage.info -X search
        # end of [[ "$BOOST_CI_CODECOV_IO_UPLOAD" != "skip" ]] section
    fi
else
    echo "Invalid parameter for codecov.sh: '$coverage_action'." >&2
    false
fi
