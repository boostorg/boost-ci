# Copyright 2019 - 2026 Alexander Grund
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE or copy at http://boost.org/LICENSE_1_0.txt)

# Install coverage collector (Similar to LCov)
& "$PSScriptRoot\install-opencppcoverage.ps1"
$env:Path += ";C:\Program Files\OpenCppCoverage"

# Run build with coverage collection
$env:B2_VARIANT = "debug"

# Use a temporary folder to avoid codecov picking up wrong files
mkdir __out

# Build command to collect coverage
$cmd = 'OpenCppCoverage.exe --export_type cobertura:__out/cobertura.xml --modules "{0}" ' -f ${env:BOOST_ROOT}
Get-ChildItem -Directory "${env:BOOST_ROOT}\libs\${env:SELF}\include" | ForEach-Object {
    if ($_.Name -eq 'boost') {
        # Boost headers are symlinked/copied to the top-level boost folder
        Get-ChildItem -Name $_.FullName | ForEach-Object {$cmd += ' --sources "boost\{0}"' -f $_}
    } else {
        # Other headers are used directly from the library's include folder
        $cmd += ' --sources "{0}"' -f $_.FullName
    }
}
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
$cmd += "--cover_children -- cmd.exe /c $PSScriptRoot\build.bat"

# Print generated command and run
$cmd
Invoke-Expression $cmd

# Normalize paths to be relative to the superproject root:
# Strip the absolute $env:BOOST_ROOT prefix and convert backslashes to forward slashes
# so that the same source file maps to the same path on Linux and Windows.
# This is required for Coveralls to combine coverage across OSes.
$xml = Get-Content __out\cobertura.xml -Raw
$xml = $xml -replace [regex]::Escape("$env:BOOST_ROOT\"), ''
$xml = $xml -replace '\\', '/'
$xml | Set-Content __out\cobertura.xml
