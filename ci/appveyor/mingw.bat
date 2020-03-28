::
:: MinGW Build Script for Appveyor, leveraging the MSYS2 installation
:: Copyright (C) 2018 - 2019 James E. King III
:: Distributed under the Boost Software License, Version 1.0.
:: (See accompanying file LICENSE_1_0.txt or copy at http://boost.org/LICENSE_1_0.txt)
::

@ECHO ON
SETLOCAL EnableDelayedExpansion

:: Set up the toolset
echo using gcc : %FLAVOR% : %ARCH%-w64-mingw32-g++.exe ; > %USERPROFILE%\user-config.jam
SET UPPERFLAVOR=%FLAVOR%
CALL :TOUPPER UPPERFLAVOR

:: Install packages needed to build boost
:: Optional: comment out ones this library does not need, 
:: so people can copy this script to another library.

FOR %%a IN ("gcc" "icu" "libiconv" "openssl" "xz" "zlib") DO (
    c:\msys64\usr\bin\env MSYSTEM=%UPPERFLAVOR% c:\msys64\usr\bin\bash -l -c ^
      "pacman --sync --needed --noconfirm %FLAVOR%/mingw-w64-%ARCH%-%%a" || EXIT /B 1
)
c:\msys64\usr\bin\env MSYSTEM=%UPPERFLAVOR% c:\msys64\usr\bin\bash -l -c ^
  "pacman --sync --needed --noconfirm python3" || EXIT /B 1

::
:: Fix older build script definitions
::

IF DEFINED CXXFLAGS (SET B2_CXXFLAGS=%CXXSTD%)
IF DEFINED CXXFLAGS (SET CXXFLAGS=)
IF DEFINED CXXSTD (SET B2_CXXSTD=%CXXSTD%)
IF DEFINED CXXSTD (SET CXXSTD=)
IF DEFINED DEFINES (SET B2_DEFINES=%CXXSTD%)
IF DEFINED DEFINES (SET DEFINES=)

::
:: Now build things...
::

c:\msys64\usr\bin\env MSYSTEM=%UPPERFLAVOR% c:\msys64\usr\bin\bash -l -c ^
  "cd %CD:\=/% && ./bootstrap.sh --with-toolset=gcc" || EXIT /B 1

c:\msys64\usr\bin\env MSYSTEM=%UPPERFLAVOR% c:\msys64\usr\bin\bash -l -c ^
  "cd %CD:\=/% && ./b2 --abbreviate-paths libs/%SELF:\=/%/test toolset=gcc-%FLAVOR% cxxstd=%B2_CXXSTD% %B2_CXXFLAGS% %B2_DEFINES% %B2_ADDRESS_MODEL% %B2_LINK% %B2_THREADING% %B2_VARIANT% -j3" || EXIT /B 1

EXIT /B 0

::
:: Function to uppercase a variable
:: from: https://stackoverflow.com/questions/34713621/batch-converting-variable-to-uppercase
::

:TOUPPER <variable>
@ECHO OFF
FOR %%a IN ("a=A" "b=B" "c=C" "d=D" "e=E" "f=F" "g=G" "h=H" "i=I"
            "j=J" "k=K" "l=L" "m=M" "n=N" "o=O" "p=P" "q=Q" "r=R"
            "s=S" "t=T" "u=U" "v=V" "w=W" "x=X" "y=Y" "z=Z"      ) DO ( CALL SET %~1=%%%~1:%%~a%% )
@ECHO ON
GOTO :EOF
