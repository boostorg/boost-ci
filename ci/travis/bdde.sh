#!/bin/bash
#
# Copyright 2019 James E. King III
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at
#      http://www.boost.org/LICENSE_1_0.txt)

# Build using a Boost Docker Development Environment container.
# The BDDE project at https://github.com/jeking3/bdde includes
# build containers for different operating systems and architectures
# using multiarch containers.  This allows for better continuous
# integration, for example you can build in a big-endian environment
# on Travis CI.
#
# In your .travis.yml file, set $BDDE_DISTRO, $BDDE_EDITION, $BDDE_ARCH
# according to the instructions in the BDDE README.

set -ex

. $(dirname "${BASH_SOURCE[0]}")/../setup_bdde.sh

. $(dirname "${BASH_SOURCE[0]}")/../enforce.sh

bdde "echo this just pulls the image"

# now we can bootstrap and build just like normal, but it is in the container
BOOST_STEM=boost bdde "./bootstrap.sh"
BOOST_STEM=boost bdde ./b2 "libs/$SELF/test" "${B2_ARGS[@]}" "$@"
