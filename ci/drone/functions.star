# Use, modification, and distribution are
# subject to the Boost Software License, Version 1.0. (See accompanying
# file LICENSE.txt)
#
# Copyright Rene Rivera 2020.

# For Drone CI we use the Starlark scripting language to reduce duplication.
# As the yaml syntax for Drone CI is rather limited.

# Downloads the script inside the directory @boostCI_dir from the master branch of BoostCI into @boostCI_dir
# Does NOT download if the file already exists, e.g. when testing BoostCI or when there is a customized file
# Then makes the script executable
def download_script_from_boostCI(filename, boostCI_dir):
  url = '$BOOST_CI_URL/%s/%s' % (boostCI_dir, filename)
  target_path = '%s/%s' % (boostCI_dir, filename)
  # Note that this always runs the `chmod` even when not downloading
  return '[ -e "{1}" ] || curl -s -S --retry 10 --create-dirs -L "{0}" -o "{1}" && chmod 755 {1}'.format(url, target_path)

# Same as above but using powershell
def download_script_from_boostCI_pwsh(filename, boostCI_dir):
  url = '$env:BOOST_CI_URL/%s/%s' % (boostCI_dir, filename)
  target_path = '%s/%s' % (boostCI_dir, filename)
  return ' '.join([
    'if(![System.IO.File]::Exists("{1}")){{',
      '$null = md "%s" -ea 0;' % boostCI_dir,
      'try{{',
        # Use pwsh.exe to invoke a potentially newer PowerShell
        'pwsh.exe -Command Invoke-WebRequest "{0}" -Outfile "{1}" -MaximumRetryCount 10 -RetryIntervalSec 15',
      '}}catch{{',
        'Invoke-WebRequest "{0}" -Outfile "{1}";',
      '}}',
    '}}',
  ]).format(url, target_path)

# Common steps for unix systems
# Takes the install script (inside the Boost.CI "ci/drone" folder) and the build script (relative to the root .drone folder)
def unix_common(install_script, buildscript_to_run):
  if not buildscript_to_run.endswith('.sh'):
    buildscript_to_run += '.sh'
  return [
    "echo '============> SETUP'",
    "uname -a",
    "echo $DRONE_STAGE_MACHINE",
    "export PATH=/usr/local/bin:$PATH",
    # Install script
    download_script_from_boostCI(install_script, 'ci/drone'),
    # Chosen build script inside .drone
    download_script_from_boostCI(buildscript_to_run, '.drone'),
    "echo '============> PACKAGES'",
    "ci/drone/" + install_script,
    "echo '============> INSTALL AND TEST'",
    ".drone/" + buildscript_to_run,
  ]

# Add the value into the env[key] if it is not None
def add_if_set(env, key, value):
  if value != None:
    env[key] = value

# Generate pipeline for Linux platform compilers.
def linux_cxx(
    # Unique name for this job
    name,
    # If set: Values for corresponding env variables, $CXX, $CXXFLAGS, ...
    cxx=None, cxxflags=None, packages=None, sources=None, llvm_os=None, llvm_ver=None,
    # Worker image and arch
    arch="amd64", image="cppalliance/ubuntu16.04:1",
    # Script to call for the build step and value of $DRONE_JOB_BUILDTYPE
    buildtype="boost", buildscript="",
    # Additional env variables, environment overwrites values in globalenv
    environment={}, globalenv={},
    triggers={ "branch": [ "master", "develop", "drone*", "bugfix/*", "feature/*", "fix/*", "pr/*" ] }, node={},
    # Run with additional privileges (e.g for ASAN)
    privileged=False):

  job_env = {
      "TRAVIS_BUILD_DIR": "/drone/src",
      "TRAVIS_OS_NAME": "linux",
      "DRONE_JOB_BUILDTYPE": buildtype,
      "BOOST_CI_URL": "https://github.com/boostorg/boost-ci/raw/master",
  }
  
  add_if_set(job_env, "CXX", cxx)
  add_if_set(job_env, "CXXFLAGS", cxxflags)
  add_if_set(job_env, "PACKAGES", packages)
  add_if_set(job_env, "SOURCES", sources)
  add_if_set(job_env, "LLVM_OS", llvm_os)
  add_if_set(job_env, "LLVM_VER", llvm_ver)
  job_env.update(globalenv)
  job_env.update(environment)

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
        "environment": job_env,
        # Installed in Docker:
        # - ppa:git-core/ppa
        # - tzdata sudo software-properties-common wget curl apt-transport-https git make cmake apt-file sudo unzip libssl-dev build-essential autotools-dev autoconf libc++-helpers automake g++ git
        "commands": unix_common("linux-cxx-install.sh", buildscript)
      }
    ]
  }

def windows_cxx(
    name,
    cxx="g++", cxxflags=None, packages=None, sources=None, llvm_os=None, llvm_ver=None,
    arch="amd64", image="cppalliance/dronevs2019",
    buildtype="boost", buildscript="",
    environment={}, globalenv={},
    triggers={ "branch": [ "master", "develop", "drone*", "bugfix/*", "feature/*", "fix/*", "pr/*" ] }, node={},
    privileged=False):

  job_env = {
      "TRAVIS_OS_NAME": "windows",
      "CXX": cxx,
      "DRONE_JOB_BUILDTYPE": buildtype,
      "BOOST_CI_URL": "https://github.com/boostorg/boost-ci/raw/master",
  }

  add_if_set(job_env, "CXXFLAGS", cxxflags)
  add_if_set(job_env, "PACKAGES", packages)
  add_if_set(job_env, "SOURCES", sources)
  add_if_set(job_env, "LLVM_OS", llvm_os)
  add_if_set(job_env, "LLVM_VER", llvm_ver)
  job_env.update(globalenv)
  job_env.update(environment)

  if not buildscript:
    buildscript = buildtype
  buildscript_to_run = buildscript + '.bat'

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
        "environment": job_env,
        "commands": [
          "echo '============> SETUP'",
          "echo $env:DRONE_STAGE_MACHINE",
          # Install script
          download_script_from_boostCI_pwsh('windows-cxx-install.bat', 'ci/drone'),
          # Chosen build script inside .drone
          download_script_from_boostCI_pwsh(buildscript_to_run, '.drone'),
          "echo '============> PACKAGES'",
          "ci/drone/windows-cxx-install.bat",
          "echo '============> INSTALL AND COMPILE'",
          "cmd /c .drone\\\\%s `& exit" % buildscript_to_run,
        ]
      }
    ]
  }

def osx_cxx(
    name,
    cxx=None, cxxflags=None, packages=None, sources=None, llvm_os=None, llvm_ver=None,
    arch="amd64", osx_version=None, xcode_version=None,
    buildtype="boost", buildscript="",
    environment={}, globalenv={},
    triggers={ "branch": [ "master", "develop", "drone*", "bugfix/*", "feature/*", "fix/*", "pr/*" ] }, node={},
    privileged=False):

  job_env = {
      "TRAVIS_OS_NAME": "osx",
      "CXX": cxx,
      "DRONE_JOB_BUILDTYPE": buildtype,
      "BOOST_CI_URL": "https://github.com/boostorg/boost-ci/raw/master",
  }

  add_if_set(job_env, "CXX", cxx)
  add_if_set(job_env, "CXXFLAGS", cxxflags)
  add_if_set(job_env, "PACKAGES", packages)
  add_if_set(job_env, "SOURCES", sources)
  add_if_set(job_env, "LLVM_OS", llvm_os)
  add_if_set(job_env, "LLVM_VER", llvm_ver)
  job_env.update(globalenv)
  job_env.update(environment)

  if not buildscript:
    buildscript = buildtype

  if xcode_version:
    job_env["DEVELOPER_DIR"] = "/Applications/Xcode-" + xcode_version +  ".app/Contents/Developer"
    if not osx_version:
        if xcode_version[0:2] in [ "14", "13"]:
            osx_version="monterey"
        elif xcode_version[0:4] in [ "12.5"]:
            osx_version="monterey"
        elif xcode_version[0:2] in [ "12","11","10"]:
            osx_version="catalina"
        elif xcode_version[0:1] in [ "9","8","7","6"]:
            osx_version="highsierra"
  elif not osx_version:
    osx_version="catalina"

  nodetmp={}
  nodetmp.update(node)
  nodetmp.update({"os": osx_version})

  return {
    "name": "OSX %s" % name,
    "kind": "pipeline",
    "type": "exec",
    "trigger": triggers,
    "platform": {
      "os": "darwin",
      "arch": arch
    },
    "node": nodetmp,
    "steps": [
      {
        "name": "Everything",
        "privileged" : privileged,
        "environment": job_env,
        "commands": unix_common("osx-cxx-install.sh", buildscript)
      }
    ]
  }

def freebsd_cxx(
    name,
    cxx=None, cxxflags=None, packages=None, sources=None, llvm_os=None, llvm_ver=None,
    arch="amd64", freebsd_version="13.1",
    buildtype="boost", buildscript="",
    environment={}, globalenv={},
    triggers={ "branch": [ "master", "develop", "drone*", "bugfix/*", "feature/*", "fix/*", "pr/*" ] }, node={},
    privileged=False):

  job_env = {
      "TRAVIS_OS_NAME": "freebsd",
      "DRONE_JOB_BUILDTYPE": buildtype,
      "BOOST_CI_URL": "https://github.com/boostorg/boost-ci/raw/master",
  }
  
  add_if_set(job_env, "CXX", cxx)
  add_if_set(job_env, "CXXFLAGS", cxxflags)
  add_if_set(job_env, "PACKAGES", packages)
  add_if_set(job_env, "SOURCES", sources)
  add_if_set(job_env, "LLVM_OS", llvm_os)
  add_if_set(job_env, "LLVM_VER", llvm_ver)
  job_env.update(globalenv)
  job_env.update(environment)

  if not buildscript:
    buildscript = buildtype

  nodetmp={}
  nodetmp.update(node)
  nodetmp.update({"os": "freebsd" + freebsd_version})

  return {
    "name": "FreeBSD %s" % name,
    "kind": "pipeline",
    "type": "exec",
    "trigger": triggers,
    "platform": {
      "os": "freebsd",
      "arch": arch
    },
    "node": nodetmp,
    "steps": [
      {
        "name": "Everything",
        "privileged" : privileged,
        "environment": job_env,
        "commands": unix_common("freebsd-cxx-install.sh", buildscript)
      }
    ]
  }
