[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9]{12}$')]
    [string]$ExpectedAccountId,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ExpectedRegion,

    [ValidateNotNullOrEmpty()]
    [string]$Profile = 'default',

    [string]$ExpectedRoleArnPattern = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$env:AWS_PAGER = ''

if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    throw 'AWS CLI is not installed or is not available on PATH.'
}

$configuredRegion = (& aws configure get region --profile $Profile 2>$null)
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($configuredRegion)) {
    throw 'No Region is configured for the requested profile.'
}
$configuredRegion = $configuredRegion.Trim()
if ($configuredRegion -ne $ExpectedRegion) {
    throw 'Configured Region does not match ExpectedRegion.'
}

$identityText = (& aws sts get-caller-identity --profile $Profile --region $ExpectedRegion --output json 2>$null)
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($identityText)) {
    throw 'STS caller-identity validation failed. Refresh the intended temporary session and retry.'
}
$identity = $identityText | ConvertFrom-Json
if ($identity.Account -ne $ExpectedAccountId) {
    throw 'Current AWS account does not match ExpectedAccountId.'
}
if ($ExpectedRoleArnPattern) {
    try {
        $roleMatches = $identity.Arn -match $ExpectedRoleArnPattern
    }
    catch {
        throw 'ExpectedRoleArnPattern is not a valid regular expression.'
    }
    if (-not $roleMatches) {
        throw 'Current caller ARN does not match ExpectedRoleArnPattern.'
    }
}

[pscustomobject]@{
    Status          = 'Confirmed'
    Profile         = $Profile
    Region          = $configuredRegion
    AccountSuffix   = $ExpectedAccountId.Substring(8, 4)
    RoleConstraint  = $(if ($ExpectedRoleArnPattern) { 'Matched' } else { 'NotRequested' })
    CredentialsShown = $false
}
