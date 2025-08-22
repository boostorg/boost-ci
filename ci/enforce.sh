#!/bin/bash
#
# Copyright 2017 - 2019 James E. King III
# Copyright 2020 - 2025 Alexander Grund
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at
#      http://www.boost.org/LICENSE_1_0.txt)
#
# Set & check B2 build variables understood by boost-ci scripts.

set -e

function get_python_executable {
    if command -v python &> /dev/null; then
        echo "python"
    elif command -v python3 &> /dev/null; then
        echo "python3"
    elif command -v python2 &> /dev/null; then
        echo "python2"
    else
       echo "Please install Python!" >&2
       false
    fi
}

function enforce_b2 {
    local old_varname=$1
    local new_varname=B2_${old_varname}

    if [ -z "${!new_varname:-}" ]; then
        if [ -n "${!old_varname:-}" ]; then
            if [ "$TRAVIS" = "true" ]; then
                local ci_script=".travis.yml"
            elif [ -n "${GITHUB_WORKFLOW:-}" ]; then
                local ci_script="${GITHUB_WORKFLOW} workflow"
            elif [ -n "${AGENT_OS:-}" ]; then
                local ci_script=".azure-pipelines.yml or azure-pipelines.yml"
            fi
            echo
            echo "WARNING: Your ${ci_script:-CI} file needs to be updated:"
            echo "         use ${new_varname} instead of ${old_varname}"
            echo
            export "${new_varname}"="${!old_varname}"
            unset "${old_varname}"
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
if [ -z "${B2_CXXSTD:-}" ]; then
    export B2_CXXSTD=11
fi

# default parallel build jobs: number of CPUs available + 1
if [ -z "${B2_JOBS:-}" ]; then
    pythonexecutable=$(get_python_executable)
    cpus=$(grep -c 'processor' /proc/cpuinfo || $pythonexecutable -c 'import multiprocessing as mp; print(mp.cpu_count())' || echo "2")
    export B2_JOBS=$((cpus + 1))
fi

# Error checking
if [ -z "${B2_CI_VERSION:-}" ]; then
  # B2_CI_VERSION is not set. That is acceptable. Treat it as v1 rather than v0, wherever relevant.
  true
elif [[ ! $B2_CI_VERSION =~ ^[0-9]$ ]] || ((B2_CI_VERSION > 1)); then
    # This requirement could be modified in the distant future, allowing B2_CI_VERSION > 1
    echo "B2_CI_VERSION must be a numeric value <= 1, unset or empty. Found: '$B2_CI_VERSION'"
    echo "Please correct this. Exiting."
    exit 1
fi

# Build cmdline arguments for B2 in the array B2_ARGS to preserve quotes
if ((${B2_CI_VERSION:-1} > 0)); then
  function append_b2_args {
      # Generate multiple "option=value" entries from the value of an environment variable
      # Handles correct splitting and quoting
      local var_name="$1"
      local option_name="$2"
      if [ -n "${!var_name:-}" ]; then
          while IFS= read -r -d '' value; do
              # If the value has an assignment and a space we need to quote it
              if [[ $value == *"="*" "* ]]; then
                B2_ARGS+=("${option_name}=${value%%=*}=\"${value#*=}\"")
              else
                B2_ARGS+=("${option_name}=${value}")
              fi
          done < <(echo "${!var_name}" | xargs -n 1 printf '%s\0')
      fi
  }

  B2_ARGS=(
      ${B2_TOOLSET:+"toolset=$B2_TOOLSET"}
      "cxxstd=$B2_CXXSTD"
      ${B2_CXXFLAGS:+"cxxflags=$B2_CXXFLAGS"}
  )
  append_b2_args B2_DEFINES define
  append_b2_args B2_INCLUDE include
  # shellcheck disable=SC2206
  B2_ARGS=(
      "${B2_ARGS[@]}"
      ${B2_LINKFLAGS:+"linkflags=$B2_LINKFLAGS"}
      ${B2_TESTFLAGS:-}
      ${B2_ADDRESS_MODEL:+address-model=$B2_ADDRESS_MODEL}
      ${B2_LINK:+link=$B2_LINK}
      ${B2_VISIBILITY:+visibility=$B2_VISIBILITY}
      ${B2_STDLIB:+"stdlib=$B2_STDLIB"}
      ${B2_THREADING:-}
      ${B2_VARIANT:+variant=$B2_VARIANT}
      ${B2_ASAN:+address-sanitizer=norecover}
      ${B2_TSAN:+thread-sanitizer=norecover}
      ${B2_UBSAN:+undefined-sanitizer=norecover}
      -j"${B2_JOBS}"
      ${B2_FLAGS:-}
  )
else
  # Legacy codepath for compatibility for for old versions of the .github/*.yml files:
  # In (most) variables the prefix (such as "cxxflags=" for B2_CXXFLAGS) was included in the value, so it isn't added (again) here
  # shellcheck disable=SC2206
  B2_ARGS=(
      toolset="$B2_TOOLSET"
      cxxstd="$B2_CXXSTD"
      ${B2_CXXFLAGS:-}
      ${B2_DEFINES:-}
      ${B2_INCLUDE:-}
      ${B2_LINKFLAGS:-}
      ${B2_TESTFLAGS:-}
      ${B2_ADDRESS_MODEL:-}
      ${B2_LINK:-}
      ${B2_THREADING:-}
      ${B2_VARIANT:-}
      -j"${B2_JOBS}"
  )
fi
