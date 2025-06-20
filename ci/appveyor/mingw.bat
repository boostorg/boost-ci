::
:: MinGW Build Script for Appveyor, leveraging the MSYS2 installation
:: Copyright (C) 2018 - 2019 James E. King III
:: Distributed under the Boost Software License, Version 1.0.
:: (See accompanying file LICENSE_1_0.txt or copy at http://boost.org/LICENSE_1_0.txt)
::

@ECHO ON
SETLOCAL EnableDelayedExpansion

if NOT DEFINED B2_CI_VERSION (
    echo
    echo =========================== WARNING ======================
    echo B2_CI_VERSION is not set, assuming this is an old CI version and setting it to '0'.
    echo Please update your CI configuration and set B2_CI_VERSION.
    echo =========================== WARNING ======================
    echo
    set B2_CI_VERSION=0
)

:: Set up the toolset
echo using gcc : %FLAVOR% : %ARCH%-w64-mingw32-g++.exe ; > %USERPROFILE%\user-config.jam
SET UPPERFLAVOR=%FLAVOR%
CALL :TOUPPER UPPERFLAVOR

:: Update pacman. Notes about new keys and zstd archive format at https://www.msys2.org/news

if not exist "C:\TEMP" mkdir C:\TEMP

(
echo echo "Parsing pacman version"
echo upgradepacman="no"
echo pacversion=$(pacman -V ^| grep -o -E '[0-9]+\.[0-9]+\.[0-9]' ^| head -n 1 ^)
echo echo "pacman version is $pacversion"
echo arrversion=(${pacversion//./ }^)
echo majorversion=${arrversion[0]}
echo minorversion=${arrversion[1]}
echo if [ "$majorversion" -lt "5" ]; then
echo     upgradepacman="yes"
echo elif [ "$majorversion" -eq "5" ] ^&^& [ "$minorversion" -lt "2" ]; then
echo     upgradepacman="yes"
echo fi
echo if [ "$upgradepacman" = "yes" ] ; then
echo     echo "Now upgrading pacman"
echo     echo "Keys:"
echo     curl -O http://repo.msys2.org/msys/x86_64/msys2-keyring-r21.b39fb11-1-any.pkg.tar.xz
echo     curl -O http://repo.msys2.org/msys/x86_64/msys2-keyring-r21.b39fb11-1-any.pkg.tar.xz.sig
echo     pacman-key --verify msys2-keyring-r21.b39fb11-1-any.pkg.tar.xz.sig
echo     pacman --noconfirm -U msys2-keyring-r21.b39fb11-1-any.pkg.tar.xz
echo     echo "Packages:"
echo     pacman --noconfirm -U "http://repo.msys2.org/msys/x86_64/libzstd-1.4.5-2-x86_64.pkg.tar.xz"
echo     pacman --noconfirm -U "http://repo.msys2.org/msys/x86_64/zstd-1.4.5-2-x86_64.pkg.tar.xz"
echo     pacman --noconfirm -U "http://repo.msys2.org/msys/x86_64/pacman-5.2.2-5-x86_64.pkg.tar.xz"
echo else
echo     echo "Not upgrading pacman"
echo fi
)>C:\TEMP\updatepacman.sh

c:\msys64\usr\bin\bash -l -c "/c/TEMP/updatepacman.sh" || EXIT /B 1

:: Install packages needed to build boost
:: Optional: comment out ones this library does not need,
:: so people can copy this script to another library.

FOR %%a IN ("gcc" "icu" "libiconv" "openssl" "xz" "zlib") DO (
    :: check if the package has already been installed.
    c:\msys64\usr\bin\bash -l -c "pacman -Qi mingw-w64-%ARCH%-%%a" >nul 2>&1

    if %errorlevel 1 (
        c:\msys64\usr\bin\env MSYSTEM=%UPPERFLAVOR% c:\msys64\usr\bin\bash -l -c ^
        "pacman -Sy --needed --noconfirm %FLAVOR%/mingw-w64-%ARCH%-%%a" || EXIT /B 1
        )
)
c:\msys64\usr\bin\env MSYSTEM=%UPPERFLAVOR% c:\msys64\usr\bin\bash -l -c ^
  "pacman --sync --needed --noconfirm python3" || EXIT /B 1

::
:: Fix older build script definitions
::
if %B2_CI_VERSION% LSS 1 (
  IF DEFINED CXXSTD (
    SET B2_CXXSTD=%CXXSTD%
    SET CXXSTD=
  )
  :: Those 2 were broken
  IF DEFINED CXXFLAGS (EXIT /B 1)
  IF DEFINED DEFINES (EXIT /B 1)
  :: This is done by build.bat now
  IF DEFINED B2_CXXSTD (SET B2_CXXSTD=cxxstd=%B2_CXXSTD%)
)

::
:: Now build things...
::

SET B2_TOOLCXX=toolset=gcc-%FLAVOR%

c:\msys64\usr\bin\env MSYSTEM=%UPPERFLAVOR% c:\msys64\usr\bin\bash -l -c ^
  "cd %CD:\=/% && ./bootstrap.sh --with-toolset=gcc" || EXIT /B 1

c:\msys64\usr\bin\env MSYSTEM=%UPPERFLAVOR% c:\msys64\usr\bin\bash -l -c ^
  "cd %CD:\=/% && ./b2 --abbreviate-paths libs/%SELF:\=/%/test %B2_TOOLCXX% %B2_CXXSTD% %B2_CXXFLAGS% %B2_DEFINES% %B2_THREADING% %B2_ADDRESS_MODEL% %B2_LINK% %B2_VARIANT% -j3" || EXIT /B 1
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
