@ECHO OFF
REM Generic install script for Windows
REM The following CI specific environment variables need to be set:
REM - BOOST_CI_TARGET_BRANCH
REM - BOOST_CI_SRC_FOLDER

if NOT DEFINED B2_CI_VERSION (
    echo
    echo =========================== WARNING ======================
    echo B2_CI_VERSION is not set, assuming this is an old CI version and setting it to '0'.
    echo Please update your CI configuration and set B2_CI_VERSION.
    echo =========================== WARNING ======================
    echo
    set B2_CI_VERSION=0
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
cmd /c bootstrap
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
