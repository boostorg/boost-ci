# Copyright 2026 Alexander Grund
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE or copy at http://boost.org/LICENSE_1_0.txt)

$ErrorActionPreference = "Stop"

$version = '0.9.9.0'
$installer = "OpenCppCoverageSetup-x64-$version.exe"

# Download installer
$url = "https://github.com/OpenCppCoverage/OpenCppCoverage/releases/download/release-$version/$installer"
$installerPath = "$env:TEMP\$installer"
& "$PSScriptRoot\download-file.ps1" $url $installerPath

# Verify checksum
$expectedHash = 'B06E280A89D89F6901E79C58159348B68165B6101B6C5FA4B6AB4D80668B38F9231A4EE623C1B451C15DD3883E3F4E4FC8FC75DA6993FB11409E8CCEFA3574A6'
$actualHash = (Get-FileHash $installerPath -Algorithm SHA512).Hash
if ($actualHash -ne $expectedHash) {
    throw "OpenCppCoverage installer checksum mismatch!"
}

# Installation
$process = Start-Process -FilePath $installerPath `
    -ArgumentList '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-' `
    -Wait -PassThru

if ($process.ExitCode -ne 0) {
    throw "OpenCppCoverage installation failed: $($process.ExitCode)"
}

# Cleanup
Remove-Item $installerPath

Write-Host "OpenCppCoverage installed successfully."

