#! /bin/bash
#
# Copyright 2023 Alexander Grund
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at
#      http://www.boost.org/LICENSE_1_0.txt)
#
# Add APT keys
# - Each argument should be a key URL
# - $NET_RETRY_COUNT is the amount of retries attempted

set -eu

function do_add_key
{
    key_url=$1
    # If a keyserver URL (e.g. http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x1E9377A2BA9EF27F)
    # use the hash as the filename,
    # else assume the URL contains a filename, e.g. https://apt.llvm.org/llvm-snapshot.gpg.key
    if [[ "$key_url" =~ .*keyserver.*search=0x([A-F0-9]+) ]]; then
        keyfilename="${BASH_REMATCH[1]}.key"
    else
        keyfilename=$(basename -s .key "$key_url")
    fi
    echo -e "\tDownloading APT key from '$key_url' to '$keyfilename'"
    for i in {1..${NET_RETRY_COUNT:-3}}; do
        curl -sSL --retry ${NET_RETRY_COUNT:-5} "$key_url" | sudo gpg --dearmor > /etc/apt/trusted.gpg.d/${keyfilename} && return 0 || sleep 10
    done

    return 1 # Failed
}

for key_url in "$@"; do
    do_add_key "$key_url"
done
