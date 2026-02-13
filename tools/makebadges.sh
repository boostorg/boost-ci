#!/bin/bash
#
# Generates markdown for README build status badges.
#
# Copyright 2025 James E. King III <jking@apache.org>
#

set -eu

#!/bin/bash

usage() {
  cat << EOF
Usage: $0 [OPTIONS]

Generate a markdown table with badges suitable for a README.md file in a Boost library repository.

Options:
  -r, --repo REPO        The name of the Boost library repository (e.g., "uuid").
  -b, --appveyorbadge ID The appveyor badge id (e.g., "xmeanhs47ke0dpo9" for uuid).
  -o, --appveyororg ORG  The appveyor organization (default: "cppalliance").
  -c, --codecovbadge ID  The codecov.io badge id (e.g., "6falIr5npV" for uuid).
  -y, --coverity PROJ    The coverity project name (e.g., "boostorg-uuid").
  -p, --azure            Include an Azure Pipelines column.
  -d, --drone            Include a Drone column.
  -n, --notcode          Hide Deps, Docs, and Tests columns and skip the "develop" branch.
  -h, --help             Display this help message

Note:
  - Project tokens are considered secrets.  Do not use them in badge slugs. Find them in the
    "Badges" settings of your AppVeyor or codecov.io project for that repository.
EOF
  exit 1
}

ORIGARGS=$@
ARGS=$(getopt --longoptions "repo:,appveyor:,appveyororg:,codecovbadge:,coverity:,azure,drone,notcode,help" "r:a:o:c:v:y:pdnh" -- "$@")

if [ $? -ne 0 ]; then
  echo "Failed to parse options" >&2
  usage
fi

eval set -- "$ARGS"

REPO=
APPVEYORBADGEID=
APPVEYORORG=cppalliance
CODECOVBADGE=
COVERITY=
INCLUDE_AZURE=0
INCLUDE_DRONE=0
NOTCODE=0

while true; do
  case "${1:-*}" in
    -r | --repo) REPO="$2"; shift 2 ;;
    -b | --appveyorbadge) APPVEYORBADGEID="$2"; shift 2 ;;
    -o | --appveyororg) APPVEYORORG="$2"; shift 2 ;;
    -c | --codecovbadge) CODECOVBADGE="$2"; shift 2 ;;
    -y | --coverity) COVERITY="$2"; shift 2 ;;
    -h | --help) usage ;;
    -p | --azure) INCLUDE_AZURE=1; shift ;;
    -d | --drone) INCLUDE_DRONE=1; shift ;;
    -n | --notcode) NOTCODE=1; shift ;;
    --) shift ;;
     *) break ;;
  esac
done

# Compose header and separator rows
HEADER="| Branch          | GHA CI "
SEPARATOR="| :-------------: | ------ "
if [ -n "$APPVEYORBADGEID" ]; then
  HEADER="${HEADER}| Appveyor "
  SEPARATOR="${SEPARATOR}| -------- "
fi
if [ "$INCLUDE_AZURE" -eq 1 ]; then
  HEADER="${HEADER}| Azure Pipelines "
  SEPARATOR="${SEPARATOR}| --------------- "
fi
if [ "$INCLUDE_DRONE" -eq 1 ]; then
  HEADER="${HEADER}| Drone "
  SEPARATOR="${SEPARATOR}| ----- "
fi
if [ -n "$COVERITY" ]; then
  HEADER="${HEADER}| Coverity Scan "
  SEPARATOR="${SEPARATOR}| ------------- "
fi
if [ -n "$CODECOVBADGE" ]; then
  HEADER="${HEADER}| codecov.io "
  SEPARATOR="${SEPARATOR}| ---------- "
fi
if [ "$NOTCODE" -eq 0 ]; then
  HEADER="${HEADER}| Deps | Docs | Tests "
  SEPARATOR="${SEPARATOR}| ---- | ---- | ----- "
fi
HEADER="${HEADER}|"
SEPARATOR="${SEPARATOR}|"

cat <<EOF
<!-- boost-ci/tools/makebadges.sh ${ORIGARGS} -->
$HEADER
$SEPARATOR
EOF

# Helper for Azure badge
azure_badge() {
  local branch="$1"
  echo "[![Build Status](https://dev.azure.com/boostorg/${REPO}/_apis/build/status/boostorg.${REPO}?branchName=${branch})](https://dev.azure.com/boostorg/${REPO}/_build/latest?definitionId=8&branchName=${branch})"
}

# Helper for Drone badge
drone_badge() {
  local branch="$1"
  echo "[![Build Status](https://drone.cpp.al/api/badges/boostorg/${REPO}/status.svg?ref=refs/heads/${branch})](https://drone.cpp.al/boostorg/${REPO})"
}

# Compose master row
ROW="| [\`master\`](https://github.com/boostorg/${REPO}/tree/master) "
ROW="${ROW}| [![Build Status](https://github.com/boostorg/${REPO}/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/boostorg/${REPO}/actions?query=branch:master) "
if [ -n "$APPVEYORBADGEID" ]; then
  ROW="${ROW}| [![Build status](https://ci.appveyor.com/api/projects/status/${APPVEYORBADGEID}/branch/master?svg=true)](https://ci.appveyor.com/project/${APPVEYORORG}/${REPO//_/-}/branch/master) "
fi
if [ "$INCLUDE_AZURE" -eq 1 ]; then
  ROW="${ROW}| $(azure_badge master) "
fi
if [ "$INCLUDE_DRONE" -eq 1 ]; then
  ROW="${ROW}| $(drone_badge master) "
fi
if [ -n "$COVERITY" ]; then
  ROW="${ROW}| [![Coverity Scan Build Status](https://scan.coverity.com/projects/${COVERITY}/badge.svg)](https://scan.coverity.com/projects/boostorg-${REPO}) "
fi
if [ -n "$CODECOVBADGE" ]; then
  ROW="${ROW}| [![codecov](https://codecov.io/gh/boostorg/${REPO}/branch/master/graph/badge.svg?token=${CODECOVBADGE})](https://codecov.io/gh/boostorg/${REPO}/tree/master) "
fi
if [ "$NOTCODE" -eq 0 ]; then
  ROW="${ROW}| [![Deps](https://img.shields.io/badge/deps-master-brightgreen.svg)](https://pdimov.github.io/boostdep-report/master/${REPO}.html) "
  ROW="${ROW}| [![Documentation](https://img.shields.io/badge/docs-master-brightgreen.svg)](https://www.boost.org/doc/libs/master/libs/${REPO}) "
  ROW="${ROW}| [![Enter the Matrix](https://img.shields.io/badge/matrix-master-brightgreen.svg)](https://www.boost.org/development/tests/master/developer/${REPO}.html) "
fi
ROW="${ROW}|"
echo "$ROW"

# Compose develop row
if [ "$NOTCODE" -eq 0 ]; then
  ROW="| [\`develop\`](https://github.com/boostorg/${REPO}/tree/develop) "
  ROW="${ROW}| [![Build Status](https://github.com/boostorg/${REPO}/actions/workflows/ci.yml/badge.svg?branch=develop)](https://github.com/boostorg/${REPO}/actions?query=branch:develop) "
  if [ -n "$APPVEYORBADGEID" ]; then
    ROW="${ROW}| [![Build status](https://ci.appveyor.com/api/projects/status/${APPVEYORBADGEID}/branch/develop?svg=true)](https://ci.appveyor.com/project/${APPVEYORORG}/${REPO//_/-}/branch/develop) "
  fi
  if [ "$INCLUDE_AZURE" -eq 1 ]; then
    ROW="${ROW}| $(azure_badge develop) "
  fi
  if [ "$INCLUDE_DRONE" -eq 1 ]; then
    ROW="${ROW}| $(drone_badge develop) "
  fi
  if [ -n "$COVERITY" ]; then
    ROW="${ROW}| [![Coverity Scan Build Status](https://scan.coverity.com/projects/${COVERITY}/badge.svg)](https://scan.coverity.com/projects/boostorg-${REPO}) "
  fi
  if [ -n "$CODECOVBADGE" ]; then
    ROW="${ROW}| [![codecov](https://codecov.io/gh/boostorg/${REPO}/branch/develop/graph/badge.svg?token=${CODECOVBADGE})](https://codecov.io/gh/boostorg/${REPO}/tree/develop) "
  fi
  ROW="${ROW}| [![Deps](https://img.shields.io/badge/deps-develop-brightgreen.svg)](https://pdimov.github.io/boostdep-report/develop/${REPO}.html) "
  ROW="${ROW}| [![Documentation](https://img.shields.io/badge/docs-develop-brightgreen.svg)](https://www.boost.org/doc/libs/develop/libs/${REPO}) "
  ROW="${ROW}| [![Enter the Matrix](https://img.shields.io/badge/matrix-develop-brightgreen.svg)](https://www.boost.org/development/tests/develop/developer/${REPO}.html) "
  ROW="${ROW}|"
  echo "$ROW"
fi
