#!/bin/bash
#
# Copyright 2021-2024 Alexander Grund
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at
#      http://www.boost.org/LICENSE_1_0.txt)
#
# Installs and sets up ccache

set -eu
set +x

function print_on_gha {
    if [[ "${GITHUB_ACTIONS:-false}" == "true" ]]; then
        echo "$@"
    fi
} 2> /dev/null

if ! command -v ccache &> /dev/null; then
  print_on_gha "::group::Installing CCache"
  if [ -f "/etc/debian_version" ]; then
    sudo apt-get install ${NET_RETRY_COUNT:+ -o Acquire::Retries=$NET_RETRY_COUNT} -y ccache
  elif command -v brew &> /dev/null; then
    brew update > /dev/null
    if ! brew install ccache 2>&1; then
        echo "Installing CCache via Homebrew failed."
        echo "Cleaning up Python binaries and trying again"
        # Workaround issue with unexpected symlinks: https://github.com/actions/runner-images/issues/6817
        for f in 2to3 idle3 pydoc3 python3 python3-config; do
            rm /usr/local/bin/$f || true
        done
        # Try again
        brew install ccache 2>&1
    fi
  fi
  print_on_gha "::endgroup::"
fi

# Sanity check that CCache is installed, executable and works at all
ccache --version

# This also sets the default values
echo "Using cache directory of size ${B2_CCACHE_SIZE:=500M} at '${B2_CCACHE_DIR:=$HOME/.ccache}'"

if false ; then # ! ccache -z &> /dev/null; then
  print_on_gha "::warning title=CCache::Possible cache corruption detected!"
  # Might happen if the cache got corrupted
  echo "Clearing possibly corrupted CCache directory"
  rm -rf "$B2_CCACHE_DIR" "$HOME/.ccache"
fi

ccache --set-config=cache_dir="$B2_CCACHE_DIR"
ccache --set-config=max_size="$B2_CCACHE_SIZE"
ccache -z
echo "CCache config: $(ccache -p)"
