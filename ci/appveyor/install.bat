@ECHO ON

REM Handle old appveyor configs
set res=F
IF NOT DEFINED B2_CI_VERSION set res=T
IF "%B2_CI_VERSION%"=="" set res=T
IF "%B2_CI_VERSION%"=="0" set res=T
if "%res%"=="T" (
	IF DEFINED CXXFLAGS (
	  SET B2_CXXFLAGS=%CXXFLAGS%
	  SET CXXFLAGS=
	)
)
SET BOOST_CI_TARGET_BRANCH=%APPVEYOR_REPO_BRANCH%
SET BOOST_CI_SRC_FOLDER=%APPVEYOR_BUILD_FOLDER%

call %~dp0\..\common_install.bat
