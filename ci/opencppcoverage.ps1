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

# Build the OpenCppCoverage argument list (array, so nothing gets re-parsed)
$occArgs = @(
    '--export_type', 'cobertura:__out/cobertura.xml'
    '--modules', ${env:BOOST_ROOT}
)
Get-ChildItem -Directory "${env:BOOST_ROOT}\libs\${env:SELF}\include" | ForEach-Object {
    if ($_.Name -eq 'boost') {
        # Boost headers are symlinked/copied to the top-level boost folder
        Get-ChildItem -Name $_.FullName | ForEach-Object { $occArgs += @('--sources', "boost\$_") }
    } else {
        # Other headers are used directly from the library's include folder
        $occArgs += @('--sources', $_.FullName)
    }
}
# Include own cpp files
$occArgs += @('--sources', "${env:BOOST_ROOT}\libs\${env:SELF}")
$exclusions = @(
  # Lines marked with LCov or coverity exclusion comments
  '.*// LCOV_EXCL_LINE'
  '.*// coverity\[dead_error_line\]'
  # Lines containing only braces
  '\s*[}{]*\s*'
  # Lines containing only else (and opt. braces)
  '\s*(\} )?else( \{)?\s*'
)
foreach ($e in $exclusions) {
    $occArgs += @('--excluded_line_regex', $e)
}
# Handle COVERAGE_EXCLUDES: exclude source paths from coverage via --excluded_sources
if ($env:COVERAGE_EXCLUDES) {
    foreach ($p in ($env:COVERAGE_EXCLUDES -split '\r?\n')) {
        $p = $p.Trim()
        if (-not $p) { continue }
        # Patterns are relative to the library root but include/boost is moved to BOOST_ROOT/boost
        if ($p.StartsWith('include/boost/')) {
            $base = $env:BOOST_ROOT
            $p = $p.Substring('include/'.Length)
        } else {
            $base = Join-Path $env:BOOST_ROOT "libs\$env:SELF"
        }
        $full = Join-Path $base ($p -replace '/', '\')
        $occArgs += @('--excluded_sources', $full)
    }
}

# Cover all subprocess of the build script (-> b2 -> test binary)
$occArgs += @('--cover_children', '--', 'cmd.exe', '/c', "$PSScriptRoot\build.bat")

# Print generated command and run
"OpenCppCoverage.exe " + ($occArgs -join ' ')
& OpenCppCoverage.exe @occArgs

echo "Coverage Service(s) : $env:COVERAGE_SERVICE"

# Coveralls requires paths to be equal to combine coverage across OSes.
if ( "$env:COVERAGE_SERVICE" -like '*coveralls*' ) {
    # Normalize paths to be repo-relative, see codecov.sh.
    $xml = Get-Content __out\cobertura.xml -Raw
    # Path without drive letter as found in `<class filename=`
    $boostRoot = $env:BOOST_ROOT -replace '^[A-Za-z]:\\?', ''
    echo "Normalizing: Remove $boostRoot"

    # strip libs/<self>/ for test files
    $xml = $xml -replace [regex]::Escape("$boostRoot\libs\$env:SELF\"), ''
    # boost symlinks -> include/boost/
    $xml = $xml -replace [regex]::Escape("$boostRoot\boost\"), 'include\boost\'
    $xml | Set-Content __out\cobertura.xml
}
