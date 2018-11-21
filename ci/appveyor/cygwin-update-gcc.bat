::
:: cygwin additional install Script for Appveyor updates gcc
:: Copyright (C) 2018 James E. King III
:: Distributed under the Boost Software License, Version 1.0.
:: (See accompanying file LICENSE_1_0.txt or copy at http://boost.org/LICENSE_1_0.txt)
::

@ECHO ON
SETLOCAL EnableDelayedExpansion

bash.exe -lc 'wget rawgit.com/transcode-open/apt-cyg/master/apt-cyg -O apt-cyg'
bash.exe -lc 'chmod +x apt-cyg'
bash.exe -lc 'mv apt-cyg /usr/local/bin'
bash.exe -lc 'apt-cyg update'
bash.exe -lc 'apt-cyg install gcc-g++'
