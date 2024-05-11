#!/usr/bin/env python

# Copyright Alexander Grund 2021-2023
#
# Distributed under the Boost Software License, Version 1.0.
# https://www.boost.org/LICENSE_1_0.txt

import json
import os
import sys

with open(os.path.join(os.environ['BOOST_CI_SRC_FOLDER'], 'meta', 'libraries.json')) as jsonFile:
    lib_data = json.load(jsonFile)
    if isinstance(lib_data, (list, tuple)):
      if len(lib_data) > 1:
        sys.stderr.write('Found multiple libraries in meta/libraries.json. Assuming first entry is the main one.\n')
      else:
        sys.stderr.write('Unwrapping list with single entry in meta/libraries.json.\n')
      lib_data = lib_data[0]
    print(lib_data['key'])
