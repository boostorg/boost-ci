@ECHO ON
set SELF=%APPVEYOR_PROJECT_SLUG:-=_%
cd ..
git clone -b %APPVEYOR_REPO_BRANCH% --depth 1 https://github.com/boostorg/boost.git boost-root
cd boost-root
git submodule update -q --init tools/boostdep
git submodule update -q --init tools/build
git submodule update -q --init tools/inspect
xcopy /s /e /q %APPVEYOR_BUILD_FOLDER% libs\%SELF%
python tools/boostdep/depinst/depinst.py --include example --include examples --include tools %DEPINST% %SELF%
cmd /c bootstrap
b2 headers

