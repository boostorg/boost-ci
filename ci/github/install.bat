@ECHO ON

if not defined SELF(
    echo GITHUB_REPOSITORY: %GITHUB_REPOSITORY%
    for /f %%i in ("%GITHUB_REPOSITORY%") do set SELF=%%~nxi
)
echo SELF: %SELF%

echo GITHUB_BASE_REF: %GITHUB_BASE_REF%
echo GITHUB_REF: %GITHUB_REF%

if not defined GITHUB_BASE_REF set BOOST_CI_TARGET_BRANCH=%GITHUB_REF%
else set BOOST_CI_TARGET_BRANCH=%GITHUB_BASE_REF%
for /f %%i in ("%BOOST_CI_TARGET_BRANCH%") do set BOOST_CI_TARGET_BRANCH=%%~nxi
echo BOOST_CI_TARGET_BRANCH: %BOOST_CI_TARGET_BRANCH%

set BOOST_CI_SRC_FOLDER=%GITHUB_WORKSPACE%

call %~dp0\..\common_install.bat

echo SELF=%SELF%>> %GITHUB_ENV%
echo BOOST_CI_TARGET_BRANCH=%BOOST_CI_TARGET_BRANCH%>> %GITHUB_ENV%
echo BOOST_CI_SRC_FOLDER=%BOOST_CI_SRC_FOLDER%>> %GITHUB_ENV%
echo BOOST_ROOT=%BOOST_ROOT%>> %GITHUB_ENV%
