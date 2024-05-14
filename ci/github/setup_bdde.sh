#! /bin/bash
#
# Copyright 2024 Alexander Grund
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at
#      http://www.boost.org/LICENSE_1_0.txt)
#
# Setup the Boost Docker Development Environment (BDDE)
# Requires a Linux environment with root/sudo privileges

set -ex

$(dirname "${BASH_SOURCE[0]}")/../setup_bdde.sh

echo "$(pwd)/bdde/bin/linux" >> ${GITHUB_PATH}

for var in "${!BDDE_@}"; do
  echo "$var=${!var}" >> ${GITHUB_ENV}
done

echo "B2_WRAPPER=bdde" >> ${GITHUB_ENV}

if [[ "${BDDE_FIX_MANIFEST:-yes}" == "yes" ]]; then
    # Avoid: /usr/bin/windres: Can't detect architecture.
    echo "B2_DONT_EMBED_MANIFEST=1" >> ${GITHUB_ENV}
fi
