:: Copyright (c) 2018 James E. King III
::
:: Use, modification, and distribution are subject to the
:: Boost Software License, Version 1.0. (See accompanying file
:: LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)

:: Installs ICU using vcpkg
:: Requires: "ICU_BITS" set to either "x86" or "x64"

@ECHO ON
C:\tools\vcpkg\vcpkg.exe install icu:%ICU_BITS%-windows || EXIT /B
SET ICU_PATH=C:\tools\vcpkg\packages\icu_%ICU_BITS%-windows
