@ECHO ON
setlocal enabledelayedexpansion

SET BOOST_CI_TARGET_BRANCH=%BUILD_SOURCEBRANCHNAME%
SET BOOST_CI_SRC_FOLDER=%BUILD_SOURCESDIRECTORY%

call %~dp0\..\common_install.bat

REM Persist variables
@ECHO OFF
echo ##vso[task.setvariable variable=SELF]%SELF%
echo ##vso[task.setvariable variable=BOOST_ROOT]%BOOST_ROOT%
