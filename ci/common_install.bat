REM Generic install script for Windows
REM The following CI specific environment variables need to be set:
REM - BOOST_CI_TARGET_BRANCH
REM - BOOST_CI_SRC_FOLDER

@ECHO ON

if not DEFINED SELF (
    for /F "delims=" %%i in ('python %~dp0\get_libname.py') do set SELF=%%i
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
REM Old configs expect boost in source folder
cd ..
move boost-root  %BOOST_CI_SRC_FOLDER%\
set BOOST_ROOT=%BOOST_CI_SRC_FOLDER%\boost-root
cd %BOOST_ROOT%

python tools/boostdep/depinst/depinst.py --include benchmark --include example --include examples --include tools %DEPINST% %SELF:\=/% || EXIT /B 1

REM Bootstrap is not expecting B2_CXXFLAGS content so we zero it out for the bootstrap only
SET OLD_B2_CXXFLAGS=%B2_CXXFLAGS%
SET B2_CXXFLAGS=
cmd /c bootstrap
IF NOT %ERRORLEVEL% == 0 (
    type bootstrap.log
    EXIT /B 1
)
SET B2_CXXFLAGS=%OLD_B2_CXXFLAGS%

b2 headers

if DEFINED B2_CI_VERSION (
	REM Go back to lib folder to allow ci\build.bat to work
	cd libs\%SELF%
)
