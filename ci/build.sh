#!/bin/bash
#
# Copyright 2017 - 2022 James E. King III
# Copyright 2020 - 2025 Alexander Grund
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at
#      http://www.boost.org/LICENSE_1_0.txt)
#
# Bash script to perform a bjam build
#

set -eux

: "${B2_TARGETS:="libs/$SELF/test"}"

. "$(dirname "${BASH_SOURCE[0]}")"/enforce.sh

export UBSAN_OPTIONS=print_stacktrace=1,report_error_type=1,${UBSAN_OPTIONS:-}

cd "$BOOST_ROOT"

# Save previous config if present. Append to that after finish
b2_config="$BOOST_ROOT/bin.v2/config.log"
if [[ -f "$b2_config" ]]; then
  prev_config=$(mktemp)
  mv "$b2_config" "$prev_config"
  function prepend_new_config_log_to_old_config_log {
    { set +x; } 2>/dev/null
    [[ -f "$b2_config" ]] || return
    echo "=========================== END PREVIOUS CONFIG ======================" >> "$prev_config"
    cat "$b2_config" >> "$prev_config"
    mv "$prev_config" "$b2_config"
  }
  trap prepend_new_config_log_to_old_config_log EXIT
fi

# shellcheck disable=SC2086
${B2_WRAPPER:-} ./b2 ${B2_TARGETS} "${B2_ARGS[@]}" "$@"

if [ "${B2_USE_CCACHE:-0}" == "1" ] && command -v ccache &> /dev/null; then
  echo "CCache summary"
  ccache -s
fi
