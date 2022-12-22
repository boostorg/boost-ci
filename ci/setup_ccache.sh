#! /bin/bash
#
# Copyright 2021 Alexander Grund
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at
#      http://www.boost.org/LICENSE_1_0.txt)
#
# Installs and sets up ccache

set -ex

if ! command -v ccache &> /dev/null; then
  if [ -f "/etc/debian_version" ]; then
    sudo apt-get install ${NET_RETRY_COUNT:+ -o Acquire::Retries=$NET_RETRY_COUNT} -y ccache
  elif command -v brew &> /dev/null; then
    brew update > /dev/null
    if ! brew install ccache; then
        # Workaround issue with unexpected symlinks: https://github.com/actions/runner-images/issues/6817
        for f in 2to3 idle3 pydoc3 python3 python3-config; do
            rm /usr/local/bin/$f || true
        done
        # Try again
        brew install ccache
    fi
  fi
fi
ccache --set-config=cache_dir=${B2_CCACHE_DIR:-~/.ccache}
ccache --set-config=max_size=${B2_CCACHE_SIZE:-500M}
ccache -z
echo "CCache config: $(ccache -p)"
