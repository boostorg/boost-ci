@ECHO ON
cd .. || EXIT /B
git clone -b %APPVEYOR_REPO_BRANCH% --depth 1 https://github.com/boostorg/boost.git boost-root || EXIT /B
cd boost-root || EXIT /B
git submodule update -q --init libs/headers || EXIT /B
git submodule update -q --init tools/boost_install || EXIT /B
git submodule update -q --init tools/boostdep || EXIT /B
git submodule update -q --init tools/build || EXIT /B
xcopy /s /e /q /I %APPVEYOR_BUILD_FOLDER% libs\%SELF% || EXIT /B
python tools/boostdep/depinst/depinst.py --include benchmark --include example --include examples --include tools %DEPINST% %SELF:\=/% || EXIT /B
cmd /c bootstrap
IF NOT %ERRORLEVEL% == 0 (
    type bootstrap.log
    EXIT /B 1
)
b2 headers
