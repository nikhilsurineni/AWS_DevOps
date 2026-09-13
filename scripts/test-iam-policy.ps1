[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [string]$Profile = 'personal-learning',

    [ValidateNotNullOrEmpty()]
    [string]$Region = 'us-east-1'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$env:AWS_PAGER = ''

if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    throw 'AWS CLI is not installed or is not available on PATH.'
}

$policyPath = Join-Path $PSScriptRoot '..\infra\iam\learning-read-policy.json'
$resolvedPolicyPath = (Resolve-Path -LiteralPath $policyPath).Path

$actions = @(
    'iam:GetAccountSummary',
    'iam:CreateUser',
    'iam:CreateAccessKey',
    's3:ListAllMyBuckets'
)

$resultText = & aws iam simulate-custom-policy `
    --profile $Profile `
    --region $Region `
    --policy-input-list "file://$resolvedPolicyPath" `
    --action-names $actions `
    --output json 2>$null

if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($resultText)) {
    throw 'IAM policy simulation failed. Confirm the temporary session and iam:SimulateCustomPolicy permission.'
}

$result = $resultText | ConvertFrom-Json
$decisions = @{}
foreach ($item in $result.EvaluationResults) {
    $decisions[$item.EvalActionName] = $item.EvalDecision
}

$expected = @{
    'iam:GetAccountSummary' = 'allowed'
    'iam:CreateUser' = 'explicitDeny'
    'iam:CreateAccessKey' = 'explicitDeny'
    's3:ListAllMyBuckets' = 'implicitDeny'
}

foreach ($action in $expected.Keys) {
    if ($decisions[$action] -ne $expected[$action]) {
        throw "Unexpected decision for $action. Expected $($expected[$action]); received $($decisions[$action])."
    }
}

$expected.GetEnumerator() |
    Sort-Object Name |
    ForEach-Object {
        [pscustomobject]@{
            Action   = $_.Key
            Expected = $_.Value
            Observed = $decisions[$_.Key]
            Status   = 'Confirmed'
        }
    }
