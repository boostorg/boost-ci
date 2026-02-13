REM Generic build script for Windows
REM Should usually be run after common_install.bat (or the specific install.bat scripts)
REM and requires the following env variables:
REM - SELF
REM - B2_CI_VERSION (optional. Defaults to the newer method of v1 rather than v0)
REM - B2_TOOLSET

@ECHO OFF
setlocal enabledelayedexpansion

IF "%B2_CI_VERSION%" == "0" (
    echo "Only B2_CI_VERSION >= 1 is supported, got %B2_CI_VERSION%"
    exit /B 1
)

IF DEFINED ADDPATH (SET "PATH=%ADDPATH%%PATH%")

SET B2_TOOLCXX=toolset=%B2_TOOLSET%

IF DEFINED B2_CXXSTD (SET B2_CXXSTD=cxxstd=%B2_CXXSTD%)
IF DEFINED B2_CXXFLAGS (SET B2_CXXFLAGS=cxxflags=%B2_CXXFLAGS%)
IF DEFINED B2_DEFINES (SET B2_DEFINES=define=%B2_DEFINES%)
IF DEFINED B2_INCLUDE (SET B2_INCLUDE=include=%B2_INCLUDE%)
IF DEFINED B2_ADDRESS_MODEL (SET B2_ADDRESS_MODEL=address-model=%B2_ADDRESS_MODEL%)
IF DEFINED B2_TARGET_OS (SET B2_TARGET_OS=target-os=%B2_TARGET_OS%)
IF DEFINED B2_LINK (SET B2_LINK=link=%B2_LINK%)
IF DEFINED B2_VARIANT (SET B2_VARIANT=variant=%B2_VARIANT%)

set SELF_S=%SELF:\=/%
IF NOT DEFINED B2_TARGETS (SET B2_TARGETS=libs/!SELF_S!/test)
IF NOT DEFINED B2_JOBS (SET B2_JOBS=3)

REM clang-win requires to use the linker for the manifest
IF "%B2_TOOLSET%" == "clang-win" (
    IF NOT DEFINED B2_FLAGS (
        SET B2_FLAGS=embed-manifest-via=linker
    ) ELSE (
        SET B2_FLAGS=embed-manifest-via=linker %B2_FLAGS%
    )
)

cd %BOOST_ROOT%

IF DEFINED SCRIPT (
    call libs\%SELF%\%SCRIPT%
) ELSE (
    REM Echo the complete build command to the build log
    ECHO b2 --abbreviate-paths %B2_TARGETS% %B2_TOOLCXX% %B2_CXXSTD% %B2_CXXFLAGS% %B2_DEFINES% %B2_INCLUDE% %B2_THREADING% %B2_ADDRESS_MODEL% %B2_TARGET_OS% %B2_LINK% %B2_VARIANT% -j%B2_JOBS% %B2_FLAGS%
    REM Now go build...
    b2 --abbreviate-paths %B2_TARGETS% %B2_TOOLCXX% %B2_CXXSTD% %B2_CXXFLAGS% %B2_DEFINES% %B2_INCLUDE% %B2_THREADING% %B2_ADDRESS_MODEL% %B2_TARGET_OS% %B2_LINK% %B2_VARIANT% -j%B2_JOBS% %B2_FLAGS%
)
