::
:: cygwin64 additional install Script for Appveyor updates gcc
:: Copyright (C) 2018 James E. King III
:: Distributed under the Boost Software License, Version 1.0.
:: (See accompanying file LICENSE_1_0.txt or copy at http://boost.org/LICENSE_1_0.txt)
::

@ECHO ON
:: Occasionally build slaves complain about a mismatched cygwin1.dll so
:: in case that happens let's see what is going on.
WHERE cygwin1.dll

appveyor DownloadFile https://cygwin.com/setup-x86_64.exe
setup-x86_64.exe -q
