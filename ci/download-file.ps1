# Copyright 2026 Alexander Grund
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE or copy at http://boost.org/LICENSE_1_0.txt)

# Download a file with retries. Usage: download-file.ps1 <url> [<output-file>]
# The output file name is derived from the URL if not given.

[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)][string]$Uri,
    [Parameter(Position = 1)][string]$OutFile
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

if (-not $OutFile) {
    $OutFile = [IO.Path]::GetFileName(([uri]$Uri).AbsolutePath)
}

# Manual retry loop: Windows PowerShell 5.1 has no -MaximumRetryCount/-RetryIntervalSec
$maxRetries = 10
$retryDelaySec = 15

for ($attempt = 1; $attempt -le $maxRetries; $attempt++) {
    try {
        Invoke-WebRequest -Uri $Uri -OutFile $OutFile -UseBasicParsing -ErrorAction Stop
        return
    } catch {
        Write-Warning "Attempt $attempt of $maxRetries failed for $OutFile`: $($_.Exception.Message)"
        if ($attempt -lt $maxRetries) {
            Start-Sleep -Seconds $retryDelaySec
        }
    }
}
throw "Download of '$Uri' to '$OutFile' failed after $maxRetries attempts"
