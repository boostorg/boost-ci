:: Copyright (c) 2018 James E. King III
::
:: Use, modification, and distribution are subject to the
:: Boost Software License, Version 1.0. (See accompanying file
:: LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)

:: Installs icu using vcpkg

@ECHO ON
C:\tools\vcpkg\vcpkg.exe install icu:x86-windows || EXIT /B
C:\tools\vcpkg\vcpkg.exe install icu:x64-windows || EXIT /B
SET ICU_PATH_32=C:\tools\vcpkg\packages\icu_x86-windows
SET ICU_PATH_64=C:\tools\vcpkg\packages\icu_x64-windows
