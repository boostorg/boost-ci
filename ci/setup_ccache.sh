#!/bin/bash
#
# Copyright 2021-2026 Alexander Grund
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at
#      http://www.boost.org/LICENSE_1_0.txt)
#
# Installs and sets up ccache

{ set +x; } &> /dev/null
set -euo pipefail

function print_on_gha {
    [[ "${GITHUB_ACTIONS:-false}" != "true" ]] || echo "$@"
}

if ! command -v ccache &> /dev/null; then
    print_on_gha "::group::Installing CCache"
    installed=0
    if [[ -f /etc/debian_version ]]; then
        if sudo apt-get -o Acquire::Retries="${NET_RETRY_COUNT:-3}" -y -q --no-install-suggests --no-install-recommends install ccache; then
            installed=1
        fi
    fi
    if [[ $installed -eq 0 ]]; then
        # Try downloading from latest ccache GitHub releases
        if version=$(curl --retry 3 -fsSL https://api.github.com/repos/ccache/ccache/releases/latest \
          | sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p') \
          && [[ -n "$version" ]]; then
            if [[ "$(uname -s)" == "Darwin" ]]; then
                platform=darwin
            else
                platform="linux-$(uname -m)"
            fi
            url="https://github.com/ccache/ccache/releases/download/v${version}/ccache-${version}-${platform}.tar.gz"
            tmp=$(mktemp -d)
            trap 'rm -rf -- "$tmp"' EXIT
            if ! curl --retry 3 -fsSL "$url" -o "$tmp/ccache.tgz"; then
                echo "Failed to download CCache $version"
            elif tar -xzf "$tmp/ccache.tgz" -C "$tmp" --strip-components=1 \
              && sudo install -m 0755 "$tmp/ccache" /usr/local/bin/ccache; then
                echo "Installed ccache $version from GitHub release"
                if [[ -n "${GITHUB_ENV:-}" ]]; then
                    echo "CCACHE_DOWNLOADED_VERSION=$version" >> "$GITHUB_ENV"
                fi
                installed=1
            fi
        fi
        # Use brew (only) as fallback. Especially the need to update brew caches first makes this take very long.
        if [[ $installed -eq 0 ]] && command -v brew &> /dev/null; then
            if ! HOMEBREW_NO_AUTO_UPDATE=1 brew install ccache 2>&1; then
                echo "Installing CCache via Homebrew failed."
                echo "Cleaning up Python binaries and trying again"
                # Workaround issue with unexpected symlinks: https://github.com/actions/runner-images/issues/6817
                for f in 2to3 idle3 pydoc3 python3 python3-config; do
                    rm /usr/local/bin/$f 2>/dev/null || true
                done
                # Try again and let it auto update as last resort
                { HOMEBREW_NO_AUTO_UPDATE=1 brew install ccache || brew install ccache; } 2>&1
            fi
        fi
    fi
    print_on_gha "::endgroup::"
fi

print_on_gha "::group::Configuring CCache"
ccache --version

# This also sets the default values
echo "Using cache directory of size ${B2_CCACHE_SIZE:=500M} at '${B2_CCACHE_DIR:=$HOME/.ccache}'"
ccache --set-config=cache_dir="$B2_CCACHE_DIR"
ccache --set-config=max_size="$B2_CCACHE_SIZE"
ccache --cleanup
if curSize=$(du -sh "$B2_CCACHE_DIR" 2>/dev/null | cut -f1); then
    echo "Current cache size: $curSize"
fi

ccache -z
echo "CCache config: $(ccache -p)"
print_on_gha "::endgroup::"
