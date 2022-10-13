# Use, modification, and distribution are
# subject to the Boost Software License, Version 1.0. (See accompanying
# file LICENSE.txt)
#
# Copyright Rene Rivera 2020.

# For Drone CI we use the Starlark scripting language to reduce duplication.
# As the yaml syntax for Drone CI is rather limited.

# Common steps for unix systems
# Takes the install script (inside the Boost.CI "ci/drone" folder) and the build script (relative to the root .drone folder)
def unix_common(install_script, buildscript_to_run):
  # Commands to download scripts
  # Factored out for ease of writing the commands
  download_scripts = [
    # Only when not testing Boost.CI
    'if [ "$(basename "$DRONE_REPO")" != "boost-ci" ]; then',
    
    # Install script
    'wget "https://github.com/boostorg/boost-ci/raw/master/ci/drone/%s" -P ci/drone' % install_script,
    # Default build script (if not exists) 
    '[ ! -e .drone/drone.sh ] || wget "https://github.com/boostorg/boost-ci/raw/master/.drone/drone.sh" -P .drone',
    # Chosen build script inside .drone (if a filename/stem and does not exist)
    '{{ [ "$(basename "{0}")" == "{0}" ] && [ ! -e .drone/{0}.sh ]; }} || wget "https://github.com/boostorg/boost-ci/raw/master/.drone/{0}.sh" -P .drone'.format(buildscript_to_run),
    
    'fi'
  ]
  return [
    "echo '==================================> SETUP'",
    "uname -a",
    "export PATH=/usr/local/bin:$PATH",
    '\n'.join(download_scripts),

    "echo '==================================> PACKAGES'",
    "ci/drone/" + install_script,

    "echo '==================================> INSTALL AND TEST'",
    ".drone/%s.sh" % buildscript_to_run,
  ]

# Generate pipeline for Linux platform compilers.
def linux_cxx(name, cxx, cxxflags="", packages="", sources="", llvm_os="", llvm_ver="", arch="amd64", image="cppalliance/ubuntu16.04:1", buildtype="boost", buildscript="", environment={}, globalenv={}, triggers={ "branch": [ "master", "develop", "drone*", "bugfix/*", "feature/*", "fix/*", "pr/*" ] }, node={}, privileged=False):
  environment_global = {
      "TRAVIS_BUILD_DIR": "/drone/src",
      "TRAVIS_OS_NAME": "linux",
      "CXX": cxx,
      "CXXFLAGS": cxxflags,
      "PACKAGES": packages,
      "SOURCES": sources,
      "LLVM_OS": llvm_os,
      "LLVM_VER": llvm_ver,
      "DRONE_JOB_BUILDTYPE": buildtype
      }
  environment_global.update(globalenv)
  environment_current=environment_global
  environment_current.update(environment)

  if not buildscript:
    buildscript = buildtype

  return {
    "name": "Linux %s" % name,
    "kind": "pipeline",
    "type": "docker",
    "trigger": triggers,
    "platform": {
      "os": "linux",
      "arch": arch
    },
    "clone": {
       "retries": 5
    },
    "node": node,
    "steps": [
      {
        "name": "Everything",
        "image": image,
        "pull": "if-not-exists",
        "privileged" : privileged,
        "environment": environment_current,
        # Installed in Docker:
        # - ppa:git-core/ppa
        # - tzdata sudo software-properties-common wget curl apt-transport-https git make cmake apt-file sudo unzip libssl-dev build-essential autotools-dev autoconf libc++-helpers automake g++ git
        "commands": unix_common("linux-cxx-install.sh", buildscript)
      }
    ]
  }

def windows_cxx(name, cxx="g++", cxxflags="", packages="", sources="", llvm_os="", llvm_ver="", arch="amd64", image="cppalliance/dronevs2019", buildtype="boost", buildscript="", environment={}, globalenv={}, triggers={ "branch": [ "master", "develop", "drone*", "bugfix/*", "feature/*", "fix/*", "pr/*" ] }, node={}, privileged=False):
  environment_global = {
      "TRAVIS_OS_NAME": "windows",
      "CXX": cxx,
      "CXXFLAGS": cxxflags,
      "PACKAGES": packages,
      "LLVM_OS": llvm_os,
      "LLVM_VER": llvm_ver,
      "DRONE_JOB_BUILDTYPE": buildtype
    }
  environment_global.update(globalenv)
  environment_current=environment_global
  environment_current.update(environment)

  if buildscript:
    buildscript_to_run = buildscript
  else:
    buildscript_to_run = buildtype

  return {
    "name": "Windows %s" % name,
    "kind": "pipeline",
    "type": "docker",
    "trigger": triggers,
    "platform": {
      "os": "windows",
      "arch": arch
    },
    "node": node,
    "steps": [
      {
        "name": "Everything",
        "image": image,
        "pull": "if-not-exists",
        "privileged": privileged,
        "environment": environment_current,
        "commands": [
          "echo '==================================> SETUP'",
          "echo $env:DRONE_STAGE_MACHINE",
          "try { pwsh.exe -Command Invoke-WebRequest https://github.com/boostorg/boost-ci/archive/master.tar.gz -Outfile master.tar.gz -MaximumRetryCount 10 -RetryIntervalSec 15 } catch { Invoke-WebRequest https://github.com/boostorg/boost-ci/archive/master.tar.gz -Outfile master.tar.gz ; echo 'Using powershell' }",
          "tar -xvf master.tar.gz",
          "mv boost-ci-master .drone/boost-ci",
          "Remove-Item master.tar.gz",
          "echo '==================================> PACKAGES'",
          ".drone/boost-ci/ci/drone/windows-cxx-install.bat",

          "echo '==================================> INSTALL AND COMPILE'",
          "cmd /c .drone\\\%s.bat `& exit" % buildscript_to_run,
        ]
      }
    ]
  }
def osx_cxx(name, cxx, cxxflags="", packages="", sources="", llvm_os="", llvm_ver="", arch="amd64", image="", osx_version="", xcode_version="", buildtype="boost", buildscript="", environment={},  globalenv={}, triggers={ "branch": [ "master", "develop", "drone*", "bugfix/*", "feature/*", "fix/*", "pr/*" ] }, privileged=False):
  environment_global = {
      # "TRAVIS_BUILD_DIR": "/drone/src",
      "TRAVIS_OS_NAME": "osx",
      "CXX": cxx,
      "CXXFLAGS": cxxflags,
      "PACKAGES": packages,
      "LLVM_OS": llvm_os,
      "LLVM_VER": llvm_ver,
      "DRONE_JOB_BUILDTYPE": buildtype
      }
  environment_global.update(globalenv)
  environment_current=environment_global
  environment_current.update(environment)

  if not buildscript:
    buildscript = buildtype

  if xcode_version:
    environment_current.update({"DEVELOPER_DIR": "/Applications/Xcode-" + xcode_version +  ".app/Contents/Developer"})
    if not osx_version:
        if xcode_version[0:2] in [ "13"]:
            osx_version="monterey"
        elif xcode_version[0:4] in [ "12.5"]:
            osx_version="monterey"
        elif xcode_version[0:2] in [ "12","11","10"]:
            osx_version="catalina"
        elif xcode_version[0:1] in [ "9","8","7","6"]:
            osx_version="highsierra"
  else:
    osx_version="catalina"

  return {
    "name": "OSX %s" % name,
    "kind": "pipeline",
    "type": "exec",
    "trigger": triggers,
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
        # "pull": "if-not-exists",
        "privileged" : privileged,
        "environment": environment_current,
        "commands": unix_common("osx-cxx-install.sh", buildscript)
      }
    ]
  }

def freebsd_cxx(name, cxx, cxxflags="", packages="", sources="", llvm_os="", llvm_ver="", arch="amd64", image="", freebsd_version="13.1", buildtype="boost", buildscript="", environment={}, globalenv={}, triggers={ "branch": [ "master", "develop", "drone*", "bugfix/*", "feature/*", "fix/*", "pr/*" ] }, privileged=False):

  environment_global = {
      # "TRAVIS_BUILD_DIR": "/drone/src",
      "TRAVIS_OS_NAME": "freebsd",
      "CXX": cxx,
      "CXXFLAGS": cxxflags,
      "PACKAGES": packages,
      "LLVM_OS": llvm_os,
      "LLVM_VER": llvm_ver,
      "DRONE_JOB_BUILDTYPE": buildtype
      }
  environment_global.update(globalenv)
  environment_current=environment_global
  environment_current.update(environment)

  if not buildscript:
    buildscript = buildtype

  return {
    "name": "FreeBSD %s" % name,
    "kind": "pipeline",
    "type": "exec",
    "trigger": triggers,
    "platform": {
      "os": "freebsd",
      "arch": arch
    },
    "node": {
      "os": "freebsd" + freebsd_version
      },
    "steps": [
      {
        "name": "Everything",
        # "image": image,
        # "pull": "if-not-exists",
        "privileged" : privileged,
        "environment": environment_current,
        "commands": unix_common("freebsd-cxx-install.sh", buildscript)
      }
    ]
  }
