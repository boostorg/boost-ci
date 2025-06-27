#!/bin/bash

set -eu

cd "$BOOST_ROOT"
git submodule update --init --recursive --jobs 4

echo ""
echo "================================================================"
echo ""
echo "Observe the use of B2_CI_VERSION. It has usually been '1'."
echo ""
echo "================================================================"
echo ""
ugrep --hidden -r B2_CI_VERSION *

echo ""
echo ""
echo "================================================================"
echo ""
echo "Discover libraries that should set B2_CI_VERSION=0"
echo ""
echo "================================================================"
echo ""

list1=$(find . -type f -wholename "*appveyor*")
list2=$(find . -type f -wholename "*drone*")
list3=$(find . -type f -wholename "*.github/workflows/*")
list="$list1 $list2 $list3"
for file in $list; do
    if ugrep -q boost-ci $file && ! ugrep -q B2_CI_VERSION $file; then
        if grep -q -E 'B2_[A-SU-Z]*[:=][" ]*[A-Za-z]+[A-Za-z-]*=' $file; then
            echo "problematic file, set A $file"
        elif grep -q -E "B2_[A-SU-Z]*[' ]*[:=][' ]*[A-Za-z]+[A-Za-z-]*=" $file; then
            echo "problematic file, set B $file"
        fi
    fi
done

