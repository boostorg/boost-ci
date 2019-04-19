@ECHO ON
cd .. || EXIT /B
REM BOOST_BRANCH is the superproject branch we check out and build against
REM except of course the repo being built - that is always what appveyor is handed
if "%BOOST_BRANCH%" == "" (
    set BOOST_BRANCH=develop
    if "%APPVEYOR_REPO_BRANCH%" == "master" set BOOST_BRANCH=master
)
git clone -b %BOOST_BRANCH% --depth 1 https://github.com/boostorg/boost.git boost-root || EXIT /B
cd boost-root || EXIT /B
git submodule update -q --init libs/headers || EXIT /B
git submodule update -q --init tools/boost_install || EXIT /B
git submodule update -q --init tools/boostdep || EXIT /B
git submodule update -q --init tools/build || EXIT /B
xcopy /s /e /q /I %APPVEYOR_BUILD_FOLDER% libs\%SELF% || EXIT /B
python tools/boostdep/depinst/depinst.py --include benchmark --include example --include examples --include tools %DEPINST% %SELF:\=/% || EXIT /B
REM Bootstrap is not expecting cxxflags content so we zero it out for the bootstrap only
SET OLD_CXXFLAGS=%CXXFLAGS%
SET CXXFLAGS=
SET OLD_B2_CXXFLAGS=%OLD_B2_CXXFLAGS%
SET B2_CXXFLAGS=
cmd /c bootstrap
IF NOT %ERRORLEVEL% == 0 (
    type bootstrap.log
    EXIT /B 1
)
SET CXXFLAGS=%OLD_CXXFLAGS%
SET B2_CXXFLAGS=%OLD_B2_CXXFLAGS%
b2 headers
