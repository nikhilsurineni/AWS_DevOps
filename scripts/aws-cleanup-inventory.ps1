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

    [ValidateNotNullOrEmpty()]
    [string]$ProjectTag = 'OrderFlow',

    [switch]$IncludeTaggedIdentifiers
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$env:AWS_PAGER = ''

& (Join-Path $PSScriptRoot 'aws-account-preflight.ps1') -ExpectedAccountId $ExpectedAccountId -ExpectedRegion $ExpectedRegion -Profile $Profile | Out-Null

function Invoke-AwsJson {
    param([Parameter(Mandatory)][string[]]$Arguments)
    $text = (& aws @Arguments --profile $Profile --region $ExpectedRegion --output json 2>$null)
    if ($LASTEXITCODE -ne 0) {
        throw ('Read-only AWS inventory call failed: aws ' + ($Arguments -join ' '))
    }
    return ($text | ConvertFrom-Json)
}

$tagged = Invoke-AwsJson @(
    'resourcegroupstaggingapi', 'get-resources',
    '--tag-filters', "Key=Project,Values=$ProjectTag",
    '--resources-per-page', '100'
)
$arns = @($tagged.ResourceTagMappingList | ForEach-Object { $_.ResourceARN })
$byService = @{}
foreach ($arn in $arns) {
    $parts = $arn -split ':'
    $service = if ($parts.Count -gt 2) { $parts[2] } else { 'unknown' }
    if (-not $byService.ContainsKey($service)) { $byService[$service] = 0 }
    $byService[$service]++
}

$regionalCounts = [ordered]@{}
$regionalCounts.Ec2Instances = @((Invoke-AwsJson @('ec2', 'describe-instances', '--filters', 'Name=instance-state-name,Values=pending,running,stopping,stopped')).Reservations.Instances).Count
$regionalCounts.EbsVolumes = @((Invoke-AwsJson @('ec2', 'describe-volumes')).Volumes).Count
$regionalCounts.ElasticIps = @((Invoke-AwsJson @('ec2', 'describe-addresses')).Addresses).Count
$regionalCounts.NatGateways = @((Invoke-AwsJson @('ec2', 'describe-nat-gateways', '--filter', 'Name=state,Values=pending,available,deleting')).NatGateways).Count
$regionalCounts.LoadBalancers = @((Invoke-AwsJson @('elbv2', 'describe-load-balancers')).LoadBalancers).Count
$regionalCounts.RdsInstances = @((Invoke-AwsJson @('rds', 'describe-db-instances')).DBInstances).Count
$regionalCounts.EcsClusters = @((Invoke-AwsJson @('ecs', 'list-clusters')).clusterArns).Count
$regionalCounts.EksClusters = @((Invoke-AwsJson @('eks', 'list-clusters')).clusters).Count
$regionalCounts.LambdaFunctions = @((Invoke-AwsJson @('lambda', 'list-functions')).Functions).Count
$regionalCounts.SqsQueues = @((Invoke-AwsJson @('sqs', 'list-queues')).QueueUrls).Count
$regionalCounts.DynamoTables = @((Invoke-AwsJson @('dynamodb', 'list-tables')).TableNames).Count
$regionalCounts.EcrRepositories = @((Invoke-AwsJson @('ecr', 'describe-repositories')).repositories).Count

$result = [ordered]@{
    Status = 'ConfirmedReadOnly'
    Scope = @{
        Profile = $Profile
        Region = $ExpectedRegion
        AccountSuffix = $ExpectedAccountId.Substring(8, 4)
        ProjectTag = $ProjectTag
    }
    TaggedResourceCount = $arns.Count
    TaggedCountByService = $byService
    RegionalAccountWideCounts = $regionalCounts
    Limitations = @(
        'Tagging API omits untagged and unsupported resources.',
        'Regional account-wide counts may include unrelated resources.',
        'S3, global IAM, snapshots, ENIs, log groups, and recently deleted resources need separate final review.',
        'This script performs no deletion.'
    )
}
if ($IncludeTaggedIdentifiers) {
    $result.TaggedResourceIdentifiers = $arns
}
$result | ConvertTo-Json -Depth 6
