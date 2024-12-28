#!/bin/bash
#
# Generates markdown for README build status badges.
#
# Copyright 2025 James E. King III <jking@apache.org>
#

set -eu

ARGS=$(getopt --longoptions "project:,appveyor:,codecov:,coverity:" "p:a:v:y:" -- "$@")

if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi

eval set -- "$ARGS"

PROJECT=
APPVEYOR=
CODECOV=
COVERITY=

while true; do
  case "${1:-*}" in
    -p | --project) PROJECT="$2"; shift 2 ;;
    -a | --appveyor) APPVEYOR="$2"; shift 2 ;;
    -v | --codecov) CODECOV="$2"; shift 2 ;;
    -y | --coverity) COVERITY="$2"; shift 2 ;;
    --) shift ;;
     *) break ;;
  esac
done

cat <<EOF
<!-- boost-ci/tools/makebadges.sh --project ${PROJECT} --appveyor ${APPVEYOR} --codecov ${CODECOV} --coverity ${COVERITY} -->
| Branch          | GHA CI | Appveyor | Coverity Scan | codecov.io | Deps | Docs | Tests |
| :-------------: | ------ | -------- | ------------- | ---------- | ---- | ---- | ----- |
| [\`master\`](https://github.com/boostorg/${PROJECT}/tree/master) | [![Build Status](https://github.com/boostorg/${PROJECT}/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/boostorg/${PROJECT}/actions?query=branch:master) | [![Build status](https://ci.appveyor.com/api/projects/status/${APPVEYOR}/branch/master?svg=true)](https://ci.appveyor.com/project/cppalliance/${PROJECT}/branch/master) | [![Coverity Scan Build Status](https://scan.coverity.com/projects/${COVERITY}/badge.svg)](https://scan.coverity.com/projects/boostorg-${PROJECT}) | [![codecov](https://codecov.io/gh/boostorg/${PROJECT}/branch/master/graph/badge.svg?token=${CODECOV})](https://codecov.io/gh/boostorg/${PROJECT}/tree/master) | [![Deps](https://img.shields.io/badge/deps-master-brightgreen.svg)](https://pdimov.github.io/boostdep-report/master/${PROJECT}.html) | [![Documentation](https://img.shields.io/badge/docs-master-brightgreen.svg)](https://www.boost.org/doc/libs/master/libs/${PROJECT}) | [![Enter the Matrix](https://img.shields.io/badge/matrix-master-brightgreen.svg)](http://www.boost.org/development/tests/master/developer/${PROJECT}.html)
| [\`develop\`](https://github.com/boostorg/${PROJECT}/tree/develop) | [![Build Status](https://github.com/boostorg/${PROJECT}/actions/workflows/ci.yml/badge.svg?branch=develop)](https://github.com/boostorg/${PROJECT}/actions?query=branch:develop) | [![Build status](https://ci.appveyor.com/api/projects/status/${APPVEYOR}/branch/develop?svg=true)](https://ci.appveyor.com/project/cppalliance/${PROJECT}/branch/develop) | [![Coverity Scan Build Status](https://scan.coverity.com/projects/${COVERITY}/badge.svg)](https://scan.coverity.com/projects/boostorg-${PROJECT}) | [![codecov](https://codecov.io/gh/boostorg/${PROJECT}/branch/develop/graph/badge.svg?token=${CODECOV})](https://codecov.io/gh/boostorg/${PROJECT}/tree/develop) | [![Deps](https://img.shields.io/badge/deps-develop-brightgreen.svg)](https://pdimov.github.io/boostdep-report/develop/${PROJECT}.html) | [![Documentation](https://img.shields.io/badge/docs-develop-brightgreen.svg)](https://www.boost.org/doc/libs/develop/libs/${PROJECT}) | [![Enter the Matrix](https://img.shields.io/badge/matrix-develop-brightgreen.svg)](http://www.boost.org/development/tests/develop/developer/${PROJECT}.html)
EOF

