#! /bin/bash
#
# Copyright 2017 - 2019 James E. King III
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at
#      http://www.boost.org/LICENSE_1_0.txt)
#
# Enforce B2 build variables understood by boost-ci scripts.
#

set -e

function enforce_b2
{
    local old_varname=$1
    local new_varname=B2_${old_varname}

    if [ -z "${!new_varname}" ]; then
        if [ -n "${!old_varname}" ]; then
            if [ "$TRAVIS" = "true" ]; then
                local ci_script=".travis.yml"
            elif [ -n "$AGENT_OS" ]; then
                local ci_script=".azure-pipelines.yml or azure-pipelines.yml"
            fi
            echo
            echo "WARNING: Your ${ci_script} file needs to be updated:"
            echo "         use ${new_varname} instead of ${old_varname}"
            echo
            export ${new_varname}="${!old_varname}"
            unset ${old_varname}
        fi
    fi
}

enforce_b2 "CXXFLAGS"
enforce_b2 "CXXSTD"
enforce_b2 "DEFINES"
enforce_b2 "LINKFLAGS"
enforce_b2 "TESTFLAGS"
enforce_b2 "TOOLSET"

# default language level: C++11
if [ -z "$B2_CXXSTD" ]; then
    export B2_CXXSTD=11
fi

# default parallel build jobs: number of CPUs available + 1
if [ -z "${B2_JOBS}" ]; then
    cpus=$(grep -c 'processor' /proc/cpuinfo || python -c 'import multiprocessing as mp; print(mp.cpu_count())' || echo "2")
    export B2_JOBS=$((cpus + 1))
fi

# For old versions strip prefix from variables
if [ -z "$B2_CI_VERSION" ]; then
    # Skipped:
    # B2_CXXFLAGS: (Ab)used for sanitizers
    # B2_THREADING: can be threading= or threadapi=
    B2_DEFINES="${B2_DEFINES#define=}"
    B2_INCLUDE="${B2_INCLUDE#include=}"
    B2_LINKFLAGS="${B2_LINKFLAGS#linkflags=}"
    B2_ADDRESS_MODEL="${B2_ADDRESS_MODEL#address-model=}"
    B2_LINK="${B2_LINK#link=}"
    B2_VARIANT="${B2_VARIANT#variant=}"
else
    B2_CXXFLAGS=${B2_CXXFLAGS:+cxxflags=$B2_CXXFLAGS}
fi

# Build cmdline arguments for B2 as an array to preserve quotes
B2_ARGS=(
    "toolset=$B2_TOOLSET"
    "cxxstd=$B2_CXXSTD"
    $B2_CXXFLAGS
    ${B2_DEFINES:+define=$B2_DEFINES}
    ${B2_INCLUDE:+include=$B2_INCLUDE}
    ${B2_LINKFLAGS:+linkflags=$B2_LINKFLAGS}
    ${B2_TESTFLAGS}
    ${B2_ADDRESS_MODEL:+address-model=$B2_ADDRESS_MODEL}
    ${B2_LINK:+link=$B2_LINK}
    ${B2_VISIBILITY:+visibility=$B2_VISIBILITY}
    ${B2_STDLIB:+"-stdlib=$B2_STDLIB"}
    ${B2_THREADING}
    ${B2_VARIANT:+variant=$B2_VARIANT}
    ${B2_ASAN:+address-sanitizer=norecover}
    ${B2_TSAN:+thread-sanitizer=norecover}
    ${B2_UBSAN:+undefined-sanitizer=norecover}
    -j${B2_JOBS}
    ${B2_FLAGS}
)
