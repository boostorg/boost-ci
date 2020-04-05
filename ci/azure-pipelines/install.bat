@ECHO ON
setlocal enabledelayedexpansion

IF NOT DEFINED SELF (
    SET SELF=%BUILD_REPOSITORY_NAME:-=_%
    FOR /f "tokens=2 delims=/" %%a in ("!SELF!") DO SET SELF=%%a
)
SET BOOST_CI_TARGET_BRANCH=%BUILD_SOURCEBRANCHNAME%
SET BOOST_CI_SRC_FOLDER=%BUILD_SOURCESDIRECTORY%

call %~dp0\..\common_install.bat

REM Persist variables
@ECHO OFF
echo ##vso[task.setvariable variable=SELF]%SELF%
echo ##vso[task.setvariable variable=BOOST_ROOT]%BOOST_ROOT%
