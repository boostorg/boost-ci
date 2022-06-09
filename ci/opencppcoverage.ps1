# Copyright 2019 - 2021 Alexander Grund
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE or copy at http://boost.org/LICENSE_1_0.txt)

$scriptPath = split-path $MyInvocation.MyCommand.Path

# Install coverage collector (Similar to LCov)
choco install opencppcoverage
$env:Path += ";C:\Program Files\OpenCppCoverage"

# Run build with coverage collection
$env:B2_VARIANT = "debug"

# Use a temporary folder to avoid codecov picking up wrong files
mkdir __out

# Build command to collect coverage
$cmd = 'OpenCppCoverage.exe --export_type cobertura:__out/cobertura.xml --modules "{0}" ' -f ${env:BOOST_ROOT}
# Include own headers (relocated to boost\*)
$cmd += (Get-ChildItem -Name "${env:BOOST_CI_SRC_FOLDER}\include\boost").ForEach({'--sources "boost\{0}"' -f $_}) -join " "
# Include own cpp files
$cmd += " --sources ${env:BOOST_ROOT}\libs\${env:SELF} "
$exclusions = @(
  # Lines marked with LCov or coverity exclusion comments
  '.*// LCOV_EXCL_LINE'
  '.*// coverity\[dead_error_line\]'
  # Lines containing only braces
  '\s*[}{]*\s*'
  # Lines containing only else (and opt. braces)
  '\s*(\} )?else( \{)?\s*'
)
$cmd += $exclusions.ForEach({"--excluded_line_regex '{0}'" -f $_}) -join " "
# Cover all subprocess of the build script (-> b2 -> test binary)
$cmd += "--cover_children -- cmd.exe /c $scriptPath\build.bat"

echo "Starting build without running tests"
$old_B2_FLAGS = $env:B2_FLAGS
$env:B2_FLAGS += 'testing.execute=off'
Invoke-Expression "cmd.exe /c $scriptPath\build.bat"
$env:B2_FLAGS = $old_B2_FLAGS

# Print generated command and run
$cmd
echo "Starting build with coverage collection"
Invoke-Expression $cmd
