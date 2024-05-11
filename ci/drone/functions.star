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

  steps=[
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

  imagecachename=image.replace('/', '-').replace(':','-')
  if "drone_cache_mount" in job_env:
    mountpoints=[x.strip() for x in job_env["drone_cache_mount"].split(',')]
    pre_step={
      "name": "restore-cache",
      "image": "meltwater/drone-cache",
      "environment": {
        "AWS_ACCESS_KEY_ID":
          { "from_secret": "drone_cache_aws_access_key_id"},
        "AWS_SECRET_ACCESS_KEY":
          { "from_secret": "drone_cache_aws_secret_access_key"}
       },
      "pull": "if-not-exists",
      "settings": {
        "restore": "true",
        "cache_key": "{{ .Repo.Namespace }}-{{ .Repo.Name }}-{{ .Commit.Branch }}-{{ arch }}-" + imagecachename,
        "bucket": "cppalliance-drone-cache",
        "region": "us-east-2",
        "mount": mountpoints
        }
    }
    steps=[ pre_step ] + steps

  if ("drone_cache_mount" in job_env) and ("drone_cache_rebuild" in job_env and job_env['drone_cache_rebuild'] != "false" and job_env['drone_cache_rebuild'] != False):
    mountpoints=[x.strip() for x in job_env["drone_cache_mount"].split(',')]
    post_step={
      "name": "rebuild-cache",
      "image": "meltwater/drone-cache",
      "environment": {
        "AWS_ACCESS_KEY_ID":
          { "from_secret": "drone_cache_aws_access_key_id"},
        "AWS_SECRET_ACCESS_KEY":
          { "from_secret": "drone_cache_aws_secret_access_key"}
       },
      "pull": "if-not-exists",
      "settings": {
        "rebuild": "true",
        "cache_key": "{{ .Repo.Namespace }}-{{ .Repo.Name }}-{{ .Commit.Branch }}-{{ arch }}-" + imagecachename,
        "bucket": "cppalliance-drone-cache",
        "region": "us-east-2",
        "mount": mountpoints
        }
    }
    steps=steps + [ post_step ]

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
    "steps": steps
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
        if xcode_version[0:2] in [ "16", "15"]:
            osx_version="sonoma"
            arch="arm64"
        elif xcode_version[0:4] in [ "14.2", "14.3"]:
            osx_version="sonoma"
            arch="arm64"
        elif xcode_version[0:2] in [ "14", "13"]:
            osx_version="monterey"
            arch="arm64"
        elif xcode_version[0:4] in [ "12.5"]:
            osx_version="monterey"
            arch="arm64"
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

# The functions job and job_impl were added in 2023-01 to provide a simplified job syntax.
# Instead of calling linux_cxx() directly, run job() instead.
#
# Define a job, i.e. a single entry in the build matrix
# It takes values for OS, compiler and C++-standard and optional arguments.
# A value of `None` means "unset" as opposed to an empty string which for environment variables will set them to empty.
def job_impl(
        # Required:
        os, compiler, cxxstd,
        # Name of the job, a reasonable default will be generated based on the other arguments
        name=None,
        # `image` will be deduced from `os`, `arch` and `compiler` when not set
        arch='amd64', image=None,
        # Those correspond to the B2_* variables and hence arguments to b2 (with the default build.sh)
        variant=None, address_model=None, stdlib=None, defines=None, cxxflags=None, linkflags=None, testflags=None,
        # Sanitizers. Using any will set the variant to 'debug' and default `defines` to 'BOOST_NO_STRESS_TEST=1'
        valgrind=False, asan=False, ubsan=False, tsan=False,
        # Packages to install, will default to the compiler and the value of `install` (for additional packages)
        packages=None, install='',
        # If True then the LLVM repo corresponding to the Ubuntu image will be added
        add_llvm=False,
        # .drone/*.sh script to run
        buildscript='drone',
        # build type env variable (defaults to 'boost' or 'valgrind', sets the token when set to 'codecov')
        buildtype=None,
        # job specific environment
        env={},
        # Any other keyword arguments are passed directly to the *_cxx-function
        **kwargs):

  if not name:
    deduced_name = True
    name = compiler.replace('-', ' ')
    if address_model:
      name += ' x' + address_model
    if stdlib:
      name += ' ' + stdlib
    if cxxstd:
      name += ' C++' + cxxstd
    if arch != 'amd64':
      name = '%s: %s' % (arch.upper(), name)
  else:
    deduced_name = False

  cxx = compiler.replace('gcc-', 'g++-')
  if packages == None:
    packages = cxx
    if install:
      packages += ' ' + install

  env['B2_TOOLSET' if os == 'windows' else 'B2_COMPILER'] = compiler
  if cxxstd != None:
    env['B2_CXXSTD'] = cxxstd

  if valgrind:
    if buildtype == None:
      buildtype = 'valgrind'
    if testflags == None:
      testflags = 'testing.launcher=valgrind'
    env.setdefault('VALGRIND_OPTS', '--error-exitcode=1')

  if asan:
    privileged = True
    env.update({
      'B2_ASAN': '1',
      'DRONE_EXTRA_PRIVILEGED': 'True',
    })
  else:
    privileged = False

  if ubsan:
    env['B2_UBSAN'] = '1'
  if tsan:
    env['B2_TSAN'] = '1'

  # Set defaults for all sanitizers
  if valgrind or asan or ubsan:
    if variant == None:
      variant = 'debug'
    if defines == None:
      defines = 'BOOST_NO_STRESS_TEST=1'

  if variant != None:
    env['B2_VARIANT'] = variant
  if address_model != None:
    env['B2_ADDRESS_MODEL'] = address_model
  if stdlib != None:
    env['B2_STDLIB'] = stdlib
  if defines != None:
    env['B2_DEFINES'] = defines
  if cxxflags != None:
    env['B2_CXXFLAGS'] = cxxflags
  if linkflags != None:
    env['B2_LINKFLAGS'] = linkflags
  if testflags != None:
    env['B2_TESTFLAGS'] = testflags

  if buildtype == None:
    buildtype = 'boost'
  elif buildtype == 'codecov':
    env.setdefault('CODECOV_TOKEN', {'from_secret': 'codecov_token'})
  elif buildtype == 'coverity':
    env.setdefault('COVERITY_SCAN_NOTIFICATION_EMAIL', {'from_secret': 'coverity_scan_email'})
    env.setdefault('COVERITY_SCAN_TOKEN', {'from_secret': 'coverity_scan_token'})

  # Put common args of all *_cxx calls not modified below into kwargs to avoid duplicating them
  kwargs['arch'] = arch
  kwargs['buildtype'] = buildtype
  kwargs['buildscript'] = buildscript
  kwargs['environment'] = env

  if os.startswith('ubuntu'):
    if not image:
      image = 'cppalliance/droneubuntu%s:1' % os.split('-')[1].replace('.', '')
      if arch != 'amd64':
        image = image[0:-1] + 'multiarch'
    if add_llvm:
      names = {
        '1604': 'xenial',
        '1804': 'bionic',
        '2004': 'focal',
        '2204': 'jammy',
      }
      kwargs['llvm_os'] = names[image.split('ubuntu')[-1].split(':')[0]] # get part between 'ubuntu' and ':'
      kwargs['llvm_ver'] = compiler.split('-')[1]

    return linux_cxx(name, cxx, packages=packages, image=image, privileged=privileged, **kwargs)
  elif os.startswith('freebsd'):
    # Deduce version if os is `freebsd-<version>`
    parts = os.split('freebsd-')
    if len(parts) == 2:
      version = kwargs.setdefault('freebsd_version', parts[1])
      if deduced_name:
        name = '%s %s' % (kwargs['freebsd_version'], name)
    return freebsd_cxx(name, cxx, **kwargs)
  elif os.startswith('osx'):
    # If format is `osx-xcode-<version>` deduce xcode_version, else assume it is passed directly
    parts = os.split('osx-xcode-')
    if len(parts) == 2:
      version =  kwargs.setdefault('xcode_version', parts[1])
      if deduced_name:
        name = 'XCode %s: %s' % (version, name)
    return osx_cxx(name, cxx, **kwargs)
  elif os == 'windows':
    if not image:
      names = {
        'msvc-14.0': 'dronevs2015',
        'msvc-14.1': 'dronevs2017',
        'msvc-14.2': 'dronevs2019:2',
        'msvc-14.3': 'dronevs2022:1',
      }
      image = 'cppalliance/' + names[compiler]
    kwargs.setdefault('cxx', '')
    return windows_cxx(name, image=image, **kwargs)
  else:
    fail('Unknown OS:', os)
