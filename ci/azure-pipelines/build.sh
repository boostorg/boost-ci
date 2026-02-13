#!/bin/bash
#
# Copyright 2017 - 2019 James E. King III
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at
#      http://www.boost.org/LICENSE_1_0.txt)
#
# Bash script to run in Linux images of Azure Pipelines to
# perform a bjam build.
#
. $(dirname "${BASH_SOURCE[0]}")/../build.sh
