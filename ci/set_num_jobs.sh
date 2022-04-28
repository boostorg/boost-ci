#
# Copyright 2017 - 2019 James E. King III
# Copyright 2022 Alexander Grund
#
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at
#      http://www.boost.org/LICENSE_1_0.txt)
#
# Determine a good number of (build) jobs to use and stores it in B2_JOBS
#

if [ -z "${B2_JOBS:-}" ]; then
    # default parallel build jobs: number of CPUs available + 1.
    # In case of failure 2 CPUs are assumed
    cpus=$(grep -c 'processor' /proc/cpuinfo || python -c 'import multiprocessing as mp; print(mp.cpu_count())' || echo "2")
    export B2_JOBS=$((cpus + 1))
fi
