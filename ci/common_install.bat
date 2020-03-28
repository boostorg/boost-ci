REM Generic install script for Windows
REM The following CI specific environment variables need to be set:
REM - SELF
REM - BOOST_CI_TARGET_BRANCH
REM - BOOST_CI_SRC_FOLDER

@ECHO ON

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

python tools/boostdep/depinst/depinst.py --include benchmark --include example --include examples --include tools %DEPINST% %SELF:\=/% || EXIT /B 1

REM Bootstrap is not expecting cxxflags content so we zero it out for the bootstrap only
SET OLD_CXXFLAGS=%CXXFLAGS%
SET CXXFLAGS=
cmd /c bootstrap
IF NOT %ERRORLEVEL% == 0 (
    type bootstrap.log
    EXIT /B 1
)
SET CXXFLAGS=%OLD_CXXFLAGS%

b2 headers
