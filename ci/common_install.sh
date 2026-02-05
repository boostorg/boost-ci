#!/bin/bash
#
# Copyright 2017 - 2019 James E. King III
# Copyright 2019 Mateusz Loskot <mateusz at loskot dot net>
# Copyright 2020-2024 Alexander Grund
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at
#      http://www.boost.org/LICENSE_1_0.txt)
#
# Executes the install phase
#
# If your repository has additional directories beyond
# "example", "examples", "tools", and "test" then you
# can add them in the environment variable DEPINST.
# i.e. - DEPINST="--include dirname1 --include dirname2"
#
# CI specific environment variables need to be set:
# - BOOST_CI_TARGET_BRANCH
# - BOOST_CI_SRC_FOLDER
# - GIT_FETCH_JOBS to fetch in parallel
#
# Will set:
# - BOOST_BRANCH
# - BOOST_ROOT
# - SELF

set -ex

CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

function print_on_gha {
    { set +x; } &> /dev/null
    [[ "${GITHUB_ACTIONS:-false}" != "true" ]] || echo "$@"
    set -x
}

if [ -n "${XCODE_APP:-}" ]; then
  if [[ $XCODE_APP =~ ^[0-9]+.[0-9]+$ ]]; then
      XCODE_APP="Xcode_${XCODE_APP}"
  fi
  if [[ $XCODE_APP =~ ^Xcode_[0-9]+.[0-9]+$ ]]; then
      XCODE_APP="/Applications/${XCODE_APP}.app"
  fi
  sudo xcode-select -switch "${XCODE_APP}"
fi

# Setup ccache
if [ "${B2_USE_CCACHE:-}" == "1" ]; then
    if ! "$CI_DIR"/setup_ccache.sh 2>&1; then
        { set +x; } &> /dev/null
        echo
        printf '=%.0s' {1..120}
        echo
        echo "Failed to install & setup ccache!"
        echo "Will NOT use CCache for building."
        printf '=%.0s' {1..120}
        echo
        echo
        B2_USE_CCACHE=0
        print_on_gha "::error title=CCache::CCache disabled due to an error!"
        set -x
    fi
fi

print_on_gha "::group::Setup B2 variables"
. "$CI_DIR"/enforce.sh 2>&1
print_on_gha "::endgroup::"

print_on_gha "::group::Checkout and setup Boost build tree"
pythonexecutable=$(get_python_executable)
$pythonexecutable --version

if [ -z "${SELF:-}" ]; then
    export SELF=$($pythonexecutable "$CI_DIR/get_libname.py")
fi

# Handle also /refs/head/master
if [ "$BOOST_CI_TARGET_BRANCH" == "master" ] || [[ "$BOOST_CI_TARGET_BRANCH" == */master ]]; then
    export BOOST_BRANCH="master"
else
    export BOOST_BRANCH="develop"
fi

cd ..

if [ ! -d boost-root ]; then
    git clone -b $BOOST_BRANCH --depth 1 https://github.com/boostorg/boost.git boost-root
    cd boost-root
else
    cd boost-root
    git checkout $BOOST_BRANCH
    git pull --no-recurse-submodules
    git submodule update
fi

git submodule update -q --init tools/boostdep
if [ -d "libs/$SELF" ]; then
    rm -rf "libs/$SELF"
fi
mkdir -p "libs/$SELF"

# On Windows copying of symlinks to files that don't exist (yet) fails and a "fake" symlink will be created instead
# that is only recognized inside MSYS.
# Or it may fail completely during the copy with:
#    cp: cannot create symbolic link '[...]': No such file or directory
# because of security checks against the pointed-to file. Although `export CYGWIN=winsymlinks:native` could avoid that
# it will still run into issues when the file is read by e.g. Python where the "fake" symlink can't be resolved
case "${OSTYPE:-}" in
    win32 | msys | cygwin)
        # Redirect through tar to restore symlinks as-is
        tar -C "$BOOST_CI_SRC_FOLDER" -cf - . | tar -C "libs/$SELF" -xf -
        ;;
    *)
        cp -r "$BOOST_CI_SRC_FOLDER"/* "libs/$SELF/"
        ;;
esac

export BOOST_ROOT="$(pwd)"
export PATH="$(pwd):$PATH"

git --version
DEPINST_ARGS=()
if [[ -n "$GIT_FETCH_JOBS" ]]; then
    DEPINST_ARGS+=("--git_args" "--jobs $GIT_FETCH_JOBS")
fi

# shellcheck disable=SC2086
$pythonexecutable tools/boostdep/depinst/depinst.py --include benchmark --include example --include examples --include tools "${DEPINST_ARGS[@]}" $DEPINST "$SELF"
print_on_gha "::endgroup::"

print_on_gha "::group::Setup B2"
# Deduce B2_TOOLSET if unset from B2_COMPILER
if [ -z "${B2_TOOLSET:-}" ] && [ -n "${B2_COMPILER:-}" ]; then
    if [[ "$B2_COMPILER" =~ clang ]]; then
        export B2_TOOLSET=clang
    elif [[ "$B2_COMPILER" =~ gcc|g\+\+ ]]; then
        export B2_TOOLSET=gcc
    elif [[ "$B2_COMPILER" =~ icpx ]]; then
        export B2_TOOLSET=intel-linux
    else
        echo "Unknown compiler: '$B2_COMPILER'. Need either clang, gcc/g++, or icpx" >&2
        false
    fi
fi

if [[ "${B2_TOOLSET:-}" == clang* ]]; then
    # If clang was installed from LLVM APT it will not have a /usr/bin/clang++
    # so we need to add the correctly versioned llvm bin path to the PATH
    if [ -f "/etc/debian_version" ]; then
        ver=""
        if [[ "$B2_TOOLSET" == clang-* ]]; then
            ver="${B2_TOOLSET#*-}"
        elif [[ "$B2_COMPILER" == clang-* ]] || [[ "$B2_COMPILER" == clang++-* ]]; then
            # Don't change path if we do find the versioned compiler
            if ! command -v "$B2_COMPILER"; then
                ver="${B2_COMPILER#*-}"
            fi
        else
            echo "Can't get clang version from B2_TOOLSET or B2_COMPILER. Skipping PATH setting." >&2
        fi
        if [[ -n "$ver" ]]; then
            export PATH="/usr/lib/llvm-${ver}/bin:$PATH"
            ls -ls "/usr/lib/llvm-${ver}/bin" || true
            hash -r || true
        fi
    else
        # On macOS GHA try to find right clang version if a versioned clang was requested
        if [[ "${RUNNER_OS:-}" == "macOS" ]] && [[ "${B2_COMPILER:-}" =~ "clang-" ]] && ! command -v "$B2_COMPILER"; then
            clang_version=${B2_COMPILER#clang-}
            system_clang_version=$(clang --version)
            { set +x; } &> /dev/null
            if [[ ${system_clang_version} == *"clang version ${clang_version}."* ]]; then
                echo "Using system clang: $(command -v clang)"
                B2_COMPILER=clang
            else
                # When the default clang doesn't match the requested version try using the brew installed one
                if brew_clang_prefix=$(brew --prefix "llvm@$clang_version"); then
                if [[ -f "$brew_clang_prefix/bin/clang" ]]; then
                    echo "$brew_clang_prefix/bin" >> "$GITHUB_PATH"
                    echo "Found Clangs in HomeBrew: " "$brew_clang_prefix/bin/"clang* /opt/homebrew/opt/llvm/bin/clang*
                    export PATH="$brew_clang_prefix/bin:$PATH"
                    echo "Clang to be used: $(command -v clang)"
                    B2_COMPILER=clang
                else
                    echo "Failed to find Clang $clang_version as requested from B2_COMPILER=${B2_COMPILER} in system or $brew_clang_prefix"
                    if [[ -d $brew_clang_prefix ]]; then
                    echo "Available brew binaries: $(ls "$brew_clang_prefix/bin")"
                    else
                    echo "HomeBrew installation is missing"
                    fi
                    exit 1
                fi
                else
                    echo "Failed to find Clang $clang_version as requested from B2_COMPILER=${B2_COMPILER}"
                    exit 1
                fi
            fi
            set -x
        fi
    fi
    command -v clang || true
    command -v clang++ || true
    if [ -n "${B2_COMPILER:-}" ]; then
        command -v "${B2_COMPILER}" || true
    fi

    # Additionally, if B2_TOOLSET is clang variant but CXX is set to g++
    # (it is on Linux images) then boost build silently ignores B2_TOOLSET and
    # uses CXX instead
    if [[ -n "$CXX" ]] && [[ "$CXX" != clang* ]]; then
        echo "CXX is set to $CXX in this environment which would override"
        echo "the setting of B2_TOOLSET=clang, therefore we clear CXX here."
        export CXX=
    fi
fi

# Set up user-config to actually use B2_COMPILER if set
userConfigPath=$HOME/user-config.jam
if [ -n "${B2_COMPILER:-}" ]; then
    # shellcheck disable=SC2016
    echo '$B2_COMPILER set. Configuring user-config'

    # Get C++ compiler
    if [[ "$B2_COMPILER" == clang* ]] && [[ "$B2_COMPILER" != clang++* ]]; then
        CXX="${B2_COMPILER/clang/clang++}"
    elif [[ "$B2_COMPILER" =~ icpx ]]; then
        CXX="icpx"
    else
        CXX="${B2_COMPILER/gcc/g++}"
    fi


    if ! command -v "$CXX"; then
        echo "Error: Compiler $CXX was not installed properly"
        exit 1
    fi

    { set +x; } &> /dev/null
    echo "Compiler location: $(command -v "$CXX")"
    if [[ "$CXX" == *"clang++"* ]] && [ -z "$GCC_TOOLCHAIN_ROOT" ]; then
        # Show also information on selected GCC lib
       version=$($CXX -v 2>&1 || $CXX --version)
    else
        version=$($CXX --version)
    fi
    echo "Compiler version: $version"

    if [ "$B2_USE_CCACHE" == "1" ]; then
        CXX="ccache $CXX"
    fi
    export CXX

    echo -n "using $B2_TOOLSET : : $CXX" > "$userConfigPath"
    # On MSYS/Cygwin B2 needs the .exe suffix to find the compiler
    if [[ $OSTYPE == "msys" || $OSTYPE == "cygwin" ]]; then
      echo -n ".exe" >> "$userConfigPath"
    fi
    if [ -n "$GCC_TOOLCHAIN_ROOT" ]; then
        echo -n " : <compileflags>\"--gcc-toolchain=$GCC_TOOLCHAIN_ROOT\" <linkflags>\"--gcc-toolchain=$GCC_TOOLCHAIN_ROOT\"" >> "$userConfigPath"
    fi
    echo " ;" >> "$userConfigPath"

    echo "Final user-config ($userConfigPath):"
    cat "$userConfigPath"

    set -x
elif [ -f "$userConfigPath" ]; then
    { set +x; } &> /dev/null
    echo "Existing user-config ($userConfigPath):"
    cat "$userConfigPath"
    set -x
else
    echo "$userConfigPath does not exist. Will use defaults"
fi

function show_bootstrap_log
{
    cat bootstrap.log
}
print_on_gha "::endgroup::"

if [[ "${B2_DONT_BOOTSTRAP:0}" != "1" ]]; then
    print_on_gha "::group::Bootstrap B2"
    trap show_bootstrap_log ERR
    # Check if b2 already exists. This would (only) happen in a caching scenario. The purpose of caching is to save time by not recompiling everything.
    # The user may clear cache or delete b2 beforehand if they wish to rebuild.
    if [ ! -f b2 ] || ! b2_version_output=$(./b2 --version); then
        ${B2_WRAPPER:-} ./bootstrap.sh
    else
        # b2 expects versions to match
        engineversion=$(echo "$b2_version_output" | tr -s ' ' | cut -d' ' -f2 | cut -d'-' -f1)
        enginemajorversion=$(echo "${engineversion}" | cut -d'.' -f1)
        engineminorversion=$(echo "${engineversion}" | cut -d'.' -f2)
        coremajorversion=$(grep VERSION_MAJOR tools/build/src/engine/patchlevel.h | tr -s ' ' | cut -d' ' -f 3)
        coreminorversion=$(grep VERSION_MINOR tools/build/src/engine/patchlevel.h | tr -s ' ' | cut -d' ' -f 3)
        if [[ "${enginemajorversion}" == "${coremajorversion}" ]] && [[ "${engineminorversion}" == "${coreminorversion}" ]]; then
            echo "b2 already exists and has the same version number"
        else
            ${B2_WRAPPER:-} ./bootstrap.sh
        fi
    fi
    trap - ERR
    ${B2_WRAPPER:-} ./b2 -d0 headers
    print_on_gha "::endgroup::"
fi
