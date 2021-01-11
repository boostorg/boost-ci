# Use, modification, and distribution are
# subject to the Boost Software License, Version 1.0. (See accompanying
# file LICENSE.txt)
#
# Copyright Rene Rivera 2020.

# For Drone CI we use the Starlark scripting language to reduce duplication.
# As the yaml syntax for Drone CI is rather limited.

# Generate pipeline for Linux platform compilers.
def linux_cxx(name, cxx, cxxflags="", packages="", sources="", llvm_os="", llvm_ver="", arch="amd64", image="cppalliance/ubuntu16.04:1", buildtype="boost", environment={}, globalenv={}, privileged=False):
  environment_global = {
      "TRAVIS_BUILD_DIR": "/drone/src",
      "TRAVIS_OS_NAME": "linux",
      "CXX": cxx,
      "CXXFLAGS": cxxflags,
      "PACKAGES": packages,
      "SOURCES": sources,
      "LLVM_OS": llvm_os,
      "LLVM_VER": llvm_ver
      }
  environment_global.update(globalenv)
  environment_current=environment_global
  environment_current.update(environment)

  return {
    "name": "Linux %s" % name,
    "kind": "pipeline",
    "type": "docker",
    "trigger": { "branch": [ "master","develop", "drone*", "bugfix/*", "feature/*", "fix/*", "pr/*" ] },
    "platform": {
      "os": "linux",
      "arch": arch
    },
    "steps": [
      {
        "name": "Everything",
        "image": image,
        "privileged" : privileged,
        "environment": environment_current,
        "commands": [

          "echo '==================================> SETUP'",
          "uname -a",
          # Moved to Docker
          # "apt-get -o Acquire::Retries=3 update && DEBIAN_FRONTEND=noninteractive apt-get -y install tzdata && apt-get -o Acquire::Retries=3 install -y sudo software-properties-common wget curl apt-transport-https git make cmake apt-file sudo unzip libssl-dev build-essential autotools-dev autoconf libc++-helpers automake g++",
          # "for i in {1..3}; do apt-add-repository ppa:git-core/ppa && break || sleep 2; done",
          # "apt-get -o Acquire::Retries=3 update && apt-get -o Acquire::Retries=3 -y install git",
          "BOOST_CI_ORG=boostorg BOOST_CI_BRANCH=master && wget https://github.com/$BOOST_CI_ORG/boost-ci/archive/$BOOST_CI_BRANCH.tar.gz && tar -xvf $BOOST_CI_BRANCH.tar.gz && mv boost-ci-$BOOST_CI_BRANCH .drone/boost-ci",
          "echo '==================================> PACKAGES'",
          # "./.drone/linux-cxx-install.sh",
          "./.drone/boost-ci/ci/drone/linux-cxx-install.sh",

          "echo '==================================> INSTALL AND COMPILE'",
          "./.drone/%s.sh" % buildtype,
        ]
      }
    ]
  }

def windows_cxx(name, cxx="g++", cxxflags="", packages="", sources="", llvm_os="", llvm_ver="", arch="amd64", image="cppalliance/dronevs2019", buildtype="boost", environment={}, globalenv={}, privileged=False):
  environment_global = {
      "TRAVIS_OS_NAME": "windows",
      "CXX": cxx,
      "CXXFLAGS": cxxflags,
      "PACKAGES": packages,
      "LLVM_OS": llvm_os,
      "LLVM_VER": llvm_ver
    }
  environment_global.update(globalenv)
  environment_current=environment_global
  environment_current.update(environment)

  return {
    "name": "Windows %s" % name,
    "kind": "pipeline",
    "type": "docker",
    "trigger": { "branch": [ "master","develop", "drone*", "bugfix/*", "feature/*", "fix/*", "pr/*" ] },
    "platform": {
      "os": "windows",
      "arch": arch
    },
    "steps": [
      {
        "name": "Everything",
        "image": image,
        "privileged": privileged,
        "environment": environment_current,
        "commands": [
          "echo '==================================> SETUP'",
          "BOOST_CI_ORG=boostorg BOOST_CI_BRANCH=master && wget https://github.com/$BOOST_CI_ORG/boost-ci/archive/$BOOST_CI_BRANCH.tar.gz && tar -xvf $BOOST_CI_BRANCH.tar.gz && mv boost-ci-$BOOST_CI_BRANCH .drone/boost-ci",
          "echo '==================================> PACKAGES'",
          "bash.exe ./.drone/boost-ci/ci/drone/windows-msvc-install.sh",

          "echo '==================================> INSTALL AND COMPILE'",
          "bash.exe ./.drone/%s.sh" % buildtype,
        ]
      }
    ]
  }
def osx_cxx(name, cxx, cxxflags="", packages="", sources="", llvm_os="", llvm_ver="", arch="amd64", image="", osx_version="", xcode_version="", buildtype="boost", environment={},  globalenv={}, privileged=False):
  environment_global = {
      # "TRAVIS_BUILD_DIR": "/drone/src",
      "TRAVIS_OS_NAME": "osx",
      "CXX": cxx,
      "CXXFLAGS": cxxflags,
      "PACKAGES": packages,
      "LLVM_OS": llvm_os,
      "LLVM_VER": llvm_ver
      }
  environment_global.update(globalenv)
  environment_current=environment_global
  environment_current.update(environment)

  if xcode_version:
    environment_current.update({"DEVELOPER_DIR": "/Applications/Xcode-" + xcode_version +  ".app/Contents/Developer"})
    if not osx_version:
        if xcode_version[0:2] in [ "12","11","10"]:
            osx_version="catalina"
        elif xcode_version[0:1] in [ "9","8","7","6"]:
            osx_version="highsierra"
  else:
    osx_version="catalina"

  return {
    "name": "OSX %s" % name,
    "kind": "pipeline",
    "type": "exec",
    "trigger": { "branch": [ "master","develop", "drone*", "bugfix/*", "feature/*", "fix/*", "pr/*" ] },
    "platform": {
      "os": "darwin",
      "arch": arch
    },
    "node": {
      "os": osx_version
      },
    "steps": [
      {
        "name": "Everything",
        # "image": image,
        "privileged" : privileged,
        "environment": environment_current,
        "commands": [

          "echo '==================================> SETUP'",
          "uname -a",
          # "apt-get -o Acquire::Retries=3 update && apt-get -o Acquire::Retries=3 -y install git",
          "BOOST_CI_ORG=boostorg BOOST_CI_BRANCH=master && /usr/local/bin/wget https://github.com/$BOOST_CI_ORG/boost-ci/archive/$BOOST_CI_BRANCH.tar.gz && tar -xvf $BOOST_CI_BRANCH.tar.gz && mv boost-ci-$BOOST_CI_BRANCH .drone/boost-ci",
          "echo '==================================> PACKAGES'",
          "./.drone/boost-ci/ci/drone/osx-cxx-install.sh",

          "echo '==================================> INSTALL AND COMPILE'",
          "./.drone/%s.sh" % buildtype,
        ]
      }
    ]
  }

def freebsd_cxx(name, cxx, cxxflags="", packages="", sources="", llvm_os="", llvm_ver="", arch="amd64", image="", buildtype="boost", environment={}, globalenv={}, privileged=False):
    pass
