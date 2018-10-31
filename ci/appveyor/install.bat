@ECHO ON
cd .. || EXIT /B
git clone -b %APPVEYOR_REPO_BRANCH% --depth 1 https://github.com/boostorg/boost.git boost-root || EXIT /B
cd boost-root || EXIT /B
git submodule update -q --init tools/boostdep || EXIT /B
git submodule update -q --init tools/build || EXIT /B
git submodule update -q --init tools/inspect || EXIT /B
xcopy /s /e /q %APPVEYOR_BUILD_FOLDER% libs\%SELF% || EXIT /B
python tools/boostdep/depinst/depinst.py --include benchmark --include example --include examples --include tools %DEPINST% %SELF:\=/% || EXIT /B
cmd /c bootstrap || EXIT /B
b2 headers
