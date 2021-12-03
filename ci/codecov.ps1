# Copyright 2019 - 2021 Alexander Grund
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE or copy at http://boost.org/LICENSE_1_0.txt)

$ErrorActionPreference = "Stop"

$scriptPath = split-path $MyInvocation.MyCommand.Path

# Install coverage collector (Similar to LCov)
choco install opencppcoverage
$env:Path += ";C:\Program Files\OpenCppCoverage"

# Install uploader
Invoke-WebRequest -Uri https://uploader.codecov.io/latest/windows/codecov.exe -Outfile codecov.exe

# Verify integrity
if (Get-Command "gpg.exe" -ErrorAction SilentlyContinue){
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri https://keybase.io/codecovsecurity/pgp_keys.asc -OutFile codecov.asc
    Invoke-WebRequest -Uri https://uploader.codecov.io/latest/windows/codecov.exe.SHA256SUM -Outfile codecov.exe.SHA256SUM
    Invoke-WebRequest -Uri https://uploader.codecov.io/latest/windows/codecov.exe.SHA256SUM.sig -Outfile codecov.exe.SHA256SUM.sig

    $ErrorActionPreference = "Continue"
    gpg.exe --import codecov.asc
    if ($LASTEXITCODE -ne 0) { Throw "Importing the key failed." }
    gpg.exe --verify codecov.exe.SHA256SUM.sig codecov.exe.SHA256SUM
    if ($LASTEXITCODE -ne 0) { Throw "Signature validation of the SHASUM failed." }
    If ($(Compare-Object -ReferenceObject  $(($(certUtil -hashfile codecov.exe SHA256)[1], "codecov.exe") -join "  ") -DifferenceObject $(Get-Content codecov.exe.SHA256SUM)).length -eq 0) { 
        echo "SHASUM verified"
    } Else {
        exit 1
    }
}
    
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
  '\s*[{}]*\s*'
  # Lines containing only else (and opt. braces)
  '\s*(\} )?else( \{)?\s*'
)
$cmd += $exclusions.ForEach({"--excluded_line_regex '{0}'" -f $_}) -join " "
# Cover all subprocess of the build script (-> b2 -> test binary)
$cmd += "--cover_children -- cmd.exe /c $scriptPath/build.bat"

# Print generated command and run
$cmd
Invoke-Expression $cmd

if ($LASTEXITCODE -ne 0) { Throw "Coverage collection failed." }

# Workaround for https://github.com/codecov/uploader/issues/525
if("${env:APPVEYOR_PULL_REQUEST_HEAD_COMMIT}" -ne ""){ $env:APPVEYOR_REPO_COMMIT = "${env:APPVEYOR_PULL_REQUEST_HEAD_COMMIT}" }

# Upload
./codecov.exe --name Appveyor --env APPVEYOR_BUILD_WORKER_IMAGE --verbose --nonZero --dir __out --rootDir "${env:BOOST_CI_SRC_FOLDER}"
if ($LASTEXITCODE -ne 0) { Throw "Upload of coverage data failed." }
