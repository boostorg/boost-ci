# Copyright 2019 - 2021 Alexander Grund
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE or copy at http://boost.org/LICENSE_1_0.txt)

$ErrorActionPreference = "Stop"

$scriptPath = split-path $MyInvocation.MyCommand.Path

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

&"$scriptPath\opencppcoverage.ps1"
if ($LASTEXITCODE -ne 0) { Throw "Coverage collection failed." }

# Workaround for https://github.com/codecov/uploader/issues/525
if("${env:APPVEYOR_PULL_REQUEST_HEAD_COMMIT}" -ne ""){ $env:APPVEYOR_REPO_COMMIT = "${env:APPVEYOR_PULL_REQUEST_HEAD_COMMIT}" }

# Upload
./codecov.exe --name Appveyor --env APPVEYOR_BUILD_WORKER_IMAGE --verbose --nonZero --dir __out --rootDir "${env:BOOST_CI_SRC_FOLDER}"
if ($LASTEXITCODE -ne 0) { Throw "Upload of coverage data failed." }
