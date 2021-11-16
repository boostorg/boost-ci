#!/usr/bin/env python 

import os
import json

with open(os.path.join(os.environ['BOOST_CI_SRC_FOLDER'], 'meta', 'libraries.json')) as jsonFile:
    lib_data = json.load(jsonFile)
    print(lib_data['key'])
