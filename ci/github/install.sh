#!/bin/bash
#
# Copyright 2021-2025 Alexander Grund
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at
#      http://www.boost.org/LICENSE_1_0.txt)
#
# Executes the install phase for GHA
# Needs env variables:
# 	- B2_COMPILER
# 	- B2_CXXSTD
# 	- B2_SANITIZE

set -ex

# Required because inside a container the owner is root so git commands would fail.
# Note that $GITHUB_WORKSPACE != ${{github.workspace}} (in the CI yml) inside containers.
git config --global --add safe.directory "$GITHUB_WORKSPACE" || echo "Failed to set Git safe.directory" # Don't fail, just warn

BOOST_CI_TARGET_BRANCH="${GITHUB_BASE_REF:-$GITHUB_REF}"
export BOOST_CI_TARGET_BRANCH="${BOOST_CI_TARGET_BRANCH##*/}" # Extract branch name
export BOOST_CI_SRC_FOLDER="${GITHUB_WORKSPACE//\\//}"

{
  echo "BOOST_CI_TARGET_BRANCH=$BOOST_CI_TARGET_BRANCH"
  echo "BOOST_CI_SRC_FOLDER=$BOOST_CI_SRC_FOLDER"
} >> "$GITHUB_ENV"

if [[ "$B2_SANITIZE" == "yes" ]]; then
  B2_ASAN=1
  B2_UBSAN=1
  if [[ -f $BOOST_CI_SRC_FOLDER/ubsan-blacklist ]]; then
    B2_CXXFLAGS="${B2_CXXFLAGS:+$B2_CXXFLAGS }-fsanitize-blacklist=libs/$SELF/ubsan-blacklist"
  fi
  if [[ -f $BOOST_CI_SRC_FOLDER/.ubsan-ignorelist ]]; then
    export UBSAN_OPTIONS="suppressions=${BOOST_CI_SRC_FOLDER}/.ubsan-ignorelist,${UBSAN_OPTIONS}"
  fi
fi

if [[ "$RUNNER_OS" == "macOS" ]] && [[ "${B2_COMPILER:-}" =~ "clang-" ]] && ! command -v "$B2_COMPILER"; then
    { set +x; } &> /dev/null
    clang_version=${B2_COMPILER#clang-}
    if [[ $(clang --version) == *"clang version ${clang_version}."* ]]; then
        B2_COMPILER=clang
    else
        # When the default clang doesn't match the requested version try using the brew installed one
        if brew_clang_prefix=$(brew --prefix "llvm@$clang_version"); then
          echo "$brew_clang_prefix/bin" >> "$GITHUB_PATH"
          echo "Found Clangs in HomeBrew: " "$brew_clang_prefix/bin/"clang* /opt/homebrew/opt/llvm/bin/clang*
          export PATH="$brew_clang_prefix/bin:$PATH"
          echo "Clang to be used: $(command -v clang)"
          B2_COMPILER=clang
        else
            echo "Failed to find Clang $clang_version as requested from B2_COMPILER=${B2_COMPILER}"
            exit 1
        fi
    fi
    set -x
fi

. "$(dirname "${BASH_SOURCE[0]}")"/../common_install.sh

# Persist the environment for all future steps

# Set by common_install.sh
{
  echo "SELF=$SELF"
  echo "BOOST_ROOT=$BOOST_ROOT"
  echo "B2_TOOLSET=$B2_TOOLSET"
  echo "B2_COMPILER=$B2_COMPILER"
  # Usually set by the env-key of the "Setup Boost" step
  [ -z "$B2_CXXSTD" ] || echo "B2_CXXSTD=$B2_CXXSTD"
  [ -z "$B2_JOBS" ] || echo "B2_JOBS=$B2_JOBS"
  [ -z "$B2_CXXFLAGS" ] || echo "B2_CXXFLAGS=$B2_CXXFLAGS"
  [ -z "$B2_DEFINES" ] || echo "B2_DEFINES=$B2_DEFINES"
  [ -z "$B2_INCLUDE" ] || echo "B2_INCLUDE=$B2_INCLUDE"
  [ -z "$B2_LINKFLAGS" ] || echo "B2_LINKFLAGS=$B2_LINKFLAGS"
  [ -z "$B2_TESTFLAGS" ] || echo "B2_TESTFLAGS=$B2_TESTFLAGS"
  [ -z "$B2_ADDRESS_MODEL" ] || echo "B2_ADDRESS_MODEL=$B2_ADDRESS_MODEL"
  [ -z "$B2_LINK" ] || echo "B2_LINK=$B2_LINK"
  [ -z "$B2_VISIBILITY" ] || echo "B2_VISIBILITY=$B2_VISIBILITY"
  [ -z "$B2_STDLIB" ] || echo "B2_STDLIB=$B2_STDLIB"
  [ -z "$B2_THREADING" ] || echo "B2_THREADING=$B2_THREADING"
  [ -z "$B2_VARIANT" ] || echo "B2_VARIANT=$B2_VARIANT"
  [ -z "$B2_ASAN" ] || echo "B2_ASAN=$B2_ASAN"
  [ -z "$B2_TSAN" ] || echo "B2_TSAN=$B2_TSAN"
  [ -z "$B2_UBSAN" ] || echo "B2_UBSAN=$B2_UBSAN"
  [ -z "$B2_FLAGS" ] || echo "B2_FLAGS=$B2_FLAGS"
  [ -z "$B2_TARGETS" ] || echo "B2_TARGETS=$B2_TARGETS"
 # Filter out (only) the conditions from set -x
 # Write the stdout to the GitHub env file
} 2> >(grep -vF ' -z ' >&2) >> "$GITHUB_ENV"
