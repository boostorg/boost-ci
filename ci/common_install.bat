@ECHO OFF
REM Generic install script for Windows
REM The following CI specific environment variables need to be set:
REM - BOOST_CI_TARGET_BRANCH
REM - BOOST_CI_SRC_FOLDER

REM Optionally BOOTSTRAP_TOOLSET can be set to choose the toolset to bootstrap B2
REM If not set it will be deduced from B2_TOOLSET
REM The special value "auto" will let the bootstrap script automatically select one

if NOT DEFINED B2_CI_VERSION (
    REM If B2_CI_VERSION is not set, assume it is a new CI version and set it to '1'.
    set B2_CI_VERSION=1
)

@ECHO ON

if not DEFINED SELF (
    for /F "delims=" %%i in ('python %~dp0\get_libname.py') do (
        set SELF=%%i
        call set SELF=%%SELF:/=\%%
    )
)
echo SELF=%SELF%
if "%SELF%" == "" EXIT /B 1

cd .. || EXIT /B 1
REM BOOST_BRANCH is the superproject branch we check out and build against
if "%BOOST_BRANCH%" == "" (
    set BOOST_BRANCH=develop
    if "%BOOST_CI_TARGET_BRANCH%" == "master" set BOOST_BRANCH=master
)
git clone -b %BOOST_BRANCH% --depth 1 https://github.com/boostorg/boost.git boost-root || EXIT /B 1
cd boost-root || EXIT /B 1
git submodule update -q --init tools/boostdep || EXIT /B 1
xcopy /s /e /q /I %BOOST_CI_SRC_FOLDER% libs\%SELF% || EXIT /B 1
set BOOST_ROOT=%cd%

REM All further variables set affect only this batch file
SETLOCAL enabledelayedexpansion

set DEPINST_ARGS=
if not "%GIT_FETCH_JOBS%" == "" (
    set DEPINST_ARGS=--git_args "--jobs %GIT_FETCH_JOBS%"
)
python tools/boostdep/depinst/depinst.py --include benchmark --include example --include examples --include tools %DEPINST_ARGS% %DEPINST% %SELF:\=/% || EXIT /B 1

if defined ADDPATH (set "PATH=%ADDPATH%%PATH%")

@ECHO OFF
if "%B2_TOOLSET%" == "gcc" (
    set cxx_exe="g++.exe"
)else if "%B2_TOOLSET%" == "clang-win" (
    set cxx_exe="clang-cl.exe"
)else (
    set cxx_exe=""
)
if NOT %cxx_exe% == "" (
    call :GetPath %cxx_exe%,cxx_path
    call :GetVersion %cxx_exe%,cxx_version
    echo Compiler location: !cxx_path!
    echo Compiler version: !cxx_version!
)
@ECHO ON

REM Bootstrap is not expecting B2_CXXFLAGS content so we zero it out for the bootstrap only
SET B2_CXXFLAGS=

if NOT DEFINED BOOTSTRAP_TOOLSET (
    REM Convert the boost jam toolset into bootstrap.bat toolset
    REM This is a temporary workaround, we should fix bootstrap.bat to accept the same toolset names as b2

    REM If B2_TOOLSET has multiple values, we take the last one
    REM This is useful for the CI, where we may have multiple toolsets defined in the environment

    set "REST=%B2_TOOLSET%"
    :toolsetloop
    for /f "tokens=1* delims=," %%a in ("!REST!") do (
        set "LAST_TOOLSET=%%a"
        set REST=%%b
    )
    REM Remaining elements -> Go back
    if DEFINED REST goto toolsetloop

    REM Boost build does not support all toolsets/compilers, e.g. MSVC before 2013 (vc12)
    REM So we just set known values and default to "auto", which means we're building
    REM boost.build with a compiler that may not be the same as the one
    REM we are using to build the library
    set BOOTSTRAP_TOOLSET=auto
    IF "%LAST_TOOLSET%" == "msvc-12.0" SET BOOTSTRAP_TOOLSET=vc12
    IF "%LAST_TOOLSET%" == "msvc-14.0" SET BOOTSTRAP_TOOLSET=vc14
    IF "%LAST_TOOLSET%" == "msvc-14.1" SET BOOTSTRAP_TOOLSET=vc141
    IF "%LAST_TOOLSET%" == "msvc-14.2" SET BOOTSTRAP_TOOLSET=vc142
    IF "%LAST_TOOLSET%" == "msvc-14.3" SET BOOTSTRAP_TOOLSET=vc143
    IF "%LAST_TOOLSET%" == "clang" SET BOOTSTRAP_TOOLSET=clang
    IF "%LAST_TOOLSET%" == "clang-win" SET BOOTSTRAP_TOOLSET=clang-win
    IF "%LAST_TOOLSET%" == "gcc" SET BOOTSTRAP_TOOLSET=gcc
    IF "%LAST_TOOLSET%" == "mingw" SET BOOTSTRAP_TOOLSET=mingw
)
IF "%BOOTSTRAP_TOOLSET%" == "auto" SET BOOTSTRAP_TOOLSET=

cmd /c bootstrap %BOOTSTRAP_TOOLSET%
IF NOT %ERRORLEVEL% == 0 (
    type bootstrap.log
    EXIT /B 1
)

b2 -d0 headers
ENDLOCAL

if %B2_CI_VERSION% GTR 0 (
    REM Go back to lib folder to allow ci\build.bat to work
    cd libs\%SELF%
)

EXIT /B %ERRORLEVEL%

:GetPath
for %%i in (%~1) do set %~2=%%~$PATH:i
EXIT /B 0

:GetVersion
for /F "delims=" %%i in ('%~1 --version ^2^>^&^1') do set %~2=%%i & goto :done
:done
EXIT /B 0
