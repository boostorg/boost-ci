# Use, modification, and distribution are
# subject to the Boost Software License, Version 1.0. (See accompanying
# file LICENSE.txt)
#
# Copyright Rene Rivera 2020.
# Copyright Alexander Grund 2022.

# For Drone CI we use the Starlark scripting language to reduce duplication.
# As the yaml syntax for Drone CI is rather limited.

# Base environment for all jobs
globalenv={'B2_CI_VERSION': '1', 'B2_VARIANT': 'release'}

# Define a job, i.e. a single entry in the build matrix
# It takes values for OS, compiler and C++-standard and optional arguments.
# A default value of `None` is a hint that the value is 'auto-detected/-set',
# as opposed to a default of `''` (empty string) which means the value is not used.
def job(
        # Required:
        os, compiler, cxxstd,
        # Name of the job, a reasonable default will be generated based on the other arguments
        name=None,
        arch='amd64', image=None,
        # Those correspond to the B2_* variables and hence arguments to b2 (with the default build.sh)
        variant='', address_model='', stdlib='', defines=None, cxxflags='', linkflags='', testflags='',
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
        environment={}, **kwargs):

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

  env = dict(globalenv)
  env['B2_TOOLSET' if os == 'windows' else 'B2_COMPILER'] = compiler
  if cxxstd != None:
    env['B2_CXXSTD'] = cxxstd

  if valgrind:
    if buildtype == None:
      buildtype = 'valgrind'
    if not testflags:
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
    if not variant:
      variant = 'debug'
    if not defines:
      defines = 'BOOST_NO_STRESS_TEST=1'

  if variant:
    env['B2_VARIANT'] = variant
  if address_model:
    env['B2_ADDRESS_MODEL'] = address_model
  if stdlib:
    env['B2_STDLIB'] = stdlib
  if defines:
    env['B2_DEFINES'] = defines
  if cxxflags:
    env['B2_CXXFLAGS'] = cxxflags
  if linkflags:
    env['B2_LINKFLAGS'] = linkflags
  if testflags:
    env['B2_TESTFLAGS'] = testflags
  env.update(environment)
  
  if buildtype == None:
    buildtype = 'boost'
  elif buildtype == 'codecov':
    env.setdefault('CODECOV_TOKEN', {'from_secret': 'codecov_token'})

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
    if not image:
      image = os.split('-')[1]
    return freebsd_cxx(name, cxx, freebsd_version=image, **kwargs)
  elif os.startswith('osx'):
    # If format is `osx-xcode-<version>` deduce xcode_version, else assume it is passed directly
    if os.startswith('osx-xcode-'):
      xcode_version = os.split('osx-xcode-')[1] 
      kwargs['xcode_version'] = xcode_version
      if deduced_name:
        name = 'XCode %s: %s' % (xcode_version, name)
        
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


def main(ctx):
  return [
    # Windows
    job(compiler='msvc-14.0', cxxstd=None,              os='windows'),
    job(compiler='msvc-14.1', cxxstd=None,              os='windows'),
    job(compiler='msvc-14.2', cxxstd=None,              os='windows'),
    job(compiler='msvc-14.3', cxxstd=None,              os='windows'),
    job(compiler='msvc-14.0', cxxstd='14,17,20',        os='windows'),
    job(compiler='msvc-14.1', cxxstd='14,17,20',        os='windows'),
    job(compiler='msvc-14.2', cxxstd='14,17,20',        os='windows'),
    job(compiler='msvc-14.3', cxxstd='14,17,20,latest', os='windows'),
  ]

# from https://github.com/boostorg/boost-ci
load("@boost_ci//ci/drone/:functions.star", "linux_cxx","osx_cxx","freebsd_cxx","add_if_set")

def download_script_from_boostCI_pwsh(filename, boostCI_dir):
  url = '$env:BOOST_CI_URL/%s/%s' % (boostCI_dir, filename)
  target_path = '%s/%s' % (boostCI_dir, filename)
  # Note that this always runs the `chmod` even when not downloading
  return ' '.join([
    'if(![System.IO.File]::Exists("{1}")){{',
      'md "%s" -ea 0;' % boostCI_dir,
      'try{{',
        'Invoke-WebRequest "{0}" -Outfile "{1}" -MaximumRetryCount 10 -RetryIntervalSec 15',
      '}}catch{{',
        'echo "Not using retry";',
        'Invoke-WebRequest "{0}" -Outfile "{1}";',
      '}}',
    '}}',
  ]).format(url, target_path)

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