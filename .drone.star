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
    job(compiler='clang-3.5', cxxstd='03,11',             os='ubuntu-16.04'),
    job(compiler='clang-3.6', cxxstd='03,11,14',          os='ubuntu-16.04'),
    job(compiler='clang-3.8', cxxstd='03,11,14',          os='ubuntu-16.04'),
    job(compiler='clang-3.9', cxxstd='03,11,14',          os='ubuntu-18.04'),
    job(compiler='clang-4.0', cxxstd='03,11,14',          os='ubuntu-18.04'),
    job(compiler='clang-5.0', cxxstd='03,11,14,1z',       os='ubuntu-18.04'),
    job(compiler='clang-6.0', cxxstd='03,11,14,17',       os='ubuntu-18.04'),
    job(compiler='clang-7',   cxxstd='03,11,14,17',       os='ubuntu-18.04'),
    job(compiler='clang-8',   cxxstd='03,11,14,17,2a',    os='ubuntu-18.04'),
    job(compiler='clang-9',   cxxstd='03,11,14,17,2a',    os='ubuntu-18.04'),
    job(compiler='clang-10',  cxxstd='03,11,14,17,2a',    os='ubuntu-18.04'),
    job(compiler='clang-11',  cxxstd='03,11,14,17,2a',    os='ubuntu-22.04'),
    job(compiler='clang-12',  cxxstd='03,11,14,17,20',    os='ubuntu-22.04'),
    job(compiler='clang-13',  cxxstd='03,11,14,17,20,2b', os='ubuntu-22.04'),
    job(compiler='clang-14',  cxxstd='03,11,14,17,20,2b', os='ubuntu-22.04'),
    job(compiler='clang-15',  cxxstd='03,11,14,17,20,2b', os='ubuntu-22.04', add_llvm=True),

    job(compiler='gcc-4.7',   cxxstd='03,11',             os='ubuntu-16.04'),
    job(compiler='gcc-4.8',   cxxstd='03,11',             os='ubuntu-16.04'),
    job(compiler='gcc-4.9',   cxxstd='03,11',             os='ubuntu-16.04'),
    job(compiler='gcc-5',     cxxstd='03,11,14,1z',       os='ubuntu-18.04'),
    job(compiler='gcc-6',     cxxstd='03,11,14,1z',       os='ubuntu-18.04'),
    job(compiler='gcc-7',     cxxstd='03,11,14,1z',       os='ubuntu-18.04'),
    job(compiler='gcc-8',     cxxstd='03,11,14,17,2a',    os='ubuntu-18.04'),
    job(compiler='gcc-9',     cxxstd='03,11,14,17,2a',    os='ubuntu-18.04'),
    job(compiler='gcc-10',    cxxstd='03,11,14,17,20',    os='ubuntu-22.04'),
    job(compiler='gcc-11',    cxxstd='03,11,14,17,20,2b', os='ubuntu-22.04'),
    job(compiler='gcc-12',    cxxstd='03,11,14,17,20,2b', os='ubuntu-22.04'),

    job(name='Coverage', buildtype='codecov',
        compiler='gcc-8',     cxxstd='03,11,14,17,2a', os='ubuntu-18.04'),
    job(name='Coverity Scan', buildtype='coverity',
        compiler='clang',     cxxstd=None,             os='ubuntu-18.04', packages=''),
    # Sanitizers
    job(name='ASAN',  asan=True,
        compiler='gcc-12',    cxxstd='03,11,14,17,20', os='ubuntu-22.04'),
    job(name='UBSAN', ubsan=True,
        compiler='gcc-12',    cxxstd='03,11,14,17,20', os='ubuntu-22.04'),
    job(name='TSAN',  tsan=True,
        compiler='gcc-12',    cxxstd='03,11,14,17,20', os='ubuntu-22.04'),
    job(name='Clang 15 w/ sanitizers', asan=True, ubsan=True,
        compiler='clang-15',  cxxstd='03,11,14,17,20', os='ubuntu-22.04', add_llvm=True),
    job(name='Clang 11 libc++ w/ sanitizers', asan=True, ubsan=True, # libc++-11 is the latest working with ASAN: https://github.com/llvm/llvm-project/issues/59432
        compiler='clang-11',  cxxstd='03,11,14,17,20', os='ubuntu-20.04', stdlib='libc++', install='libc++-11-dev libc++abi-11-dev'),
    job(name='Valgrind', valgrind=True,
        compiler='clang-6.0', cxxstd='03,11,14,1z',    os='ubuntu-18.04', install='libc6-dbg libc++-dev libstdc++-8-dev'),

    # libc++
    job(compiler='clang-6.0', cxxstd='03,11,14,17,2a', os='ubuntu-18.04', stdlib='libc++', install='libc++-dev libc++abi-dev'),
    job(compiler='clang-7',   cxxstd='03,11,14,17,2a', os='ubuntu-20.04', stdlib='libc++', install='libc++-7-dev libc++abi-7-dev'),
    job(compiler='clang-8',   cxxstd='03,11,14,17,2a', os='ubuntu-20.04', stdlib='libc++', install='libc++-8-dev libc++abi-8-dev'),
    job(compiler='clang-9',   cxxstd='03,11,14,17,2a', os='ubuntu-20.04', stdlib='libc++', install='libc++-9-dev libc++abi-9-dev'),
    job(compiler='clang-10',  cxxstd='03,11,14,17,20', os='ubuntu-20.04', stdlib='libc++', install='libc++-10-dev libc++abi-10-dev'),
    job(compiler='clang-11',  cxxstd='03,11,14,17,20', os='ubuntu-20.04', stdlib='libc++', install='libc++-11-dev libc++abi-11-dev'),
    job(compiler='clang-12',  cxxstd='03,11,14,17,20', os='ubuntu-22.04', stdlib='libc++', install='libc++-12-dev libc++abi-12-dev libunwind-12-dev'),
    job(compiler='clang-13',  cxxstd='03,11,14,17,20', os='ubuntu-22.04', stdlib='libc++', install='libc++-13-dev libc++abi-13-dev'),
    job(compiler='clang-14',  cxxstd='03,11,14,17,20', os='ubuntu-22.04', stdlib='libc++', install='libc++-14-dev libc++abi-14-dev'),
    job(compiler='clang-15',  cxxstd='03,11,14,17,20', os='ubuntu-22.04', stdlib='libc++', install='libc++-15-dev libc++abi-15-dev', add_llvm=True),

    # FreeBSD
    job(compiler='clang-10',  cxxstd='03,11,14,17,20', os='freebsd-13.1'),
    job(compiler='clang-15',  cxxstd='03,11,14,17,20', os='freebsd-13.1'),
    job(compiler='gcc-11',    cxxstd='03,11,14,17,20', os='freebsd-13.1', linkflags='-Wl,-rpath=/usr/local/lib/gcc11'),
    # OSX
    job(compiler='clang',     cxxstd='03,11,14,17,2a',    os='osx-xcode-9.4.1'),
    job(compiler='clang',     cxxstd='03,11,14,17,2a',    os='osx-xcode-10.3'),
    job(compiler='clang',     cxxstd='03,11,14,17,2a',    os='osx-xcode-12'),
    job(compiler='clang',     cxxstd='03,11,14,17,20',    os='osx-xcode-12.5.1'),
    job(compiler='clang',     cxxstd='03,11,14,17,20',    os='osx-xcode-13.4.1'),
    job(compiler='clang',     cxxstd='03,11,14,17,20,2b', os='osx-xcode-14.1'),
    # ARM64
    job(compiler='clang-12',  cxxstd='03,11,14,17,20', os='ubuntu-20.04', arch='arm64', add_llvm=True),
    job(compiler='gcc-11',    cxxstd='03,11,14,17,20', os='ubuntu-20.04', arch='arm64'),
    # S390x
    job(compiler='clang-12',  cxxstd='03,11,14,17,20', os='ubuntu-20.04', arch='s390x', add_llvm=True),
    job(compiler='gcc-11',    cxxstd='03,11,14,17,20', os='ubuntu-20.04', arch='s390x'),
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
load("@boost_ci//ci/drone/:functions.star", "linux_cxx","windows_cxx","osx_cxx","freebsd_cxx")
