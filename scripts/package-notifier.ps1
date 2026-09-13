[CmdletBinding()]
param(
    [string]$Destination = 'artifacts/realtime-notifier.zip'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$source = Join-Path $PSScriptRoot '..\functions\realtime-notifier\handler.py'
$destinationPath = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $Destination))
$artifactRoot = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) 'artifacts'))
if (-not $destinationPath.StartsWith($artifactRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw 'Destination must remain under the repository artifacts directory.'
}
New-Item -ItemType Directory -Path (Split-Path $destinationPath) -Force | Out-Null
if (Test-Path -LiteralPath $destinationPath) {
    throw 'Destination already exists; remove it explicitly after verifying the exact path.'
}
Compress-Archive -LiteralPath $source -DestinationPath $destinationPath
Get-FileHash -Algorithm SHA256 -LiteralPath $destinationPath |
    Select-Object Algorithm, Hash, Path
