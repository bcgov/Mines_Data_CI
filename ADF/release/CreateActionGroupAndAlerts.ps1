param
(
    # General Parameters
    [Parameter(Mandatory = $true)]
    [String] $ResourceGroupName,
    [Parameter(Mandatory = $true)]
    [String] $DataFactoryName,
    [Parameter(Mandatory = $true)]
    [String] $ShortName,
    # Email / Action Group Parameters
    [Parameter(Mandatory = $false)]
    [String[]] $Emails,    
    [Parameter(Mandatory = $false)]
    [String[]] $EmailUserNames,
    [Parameter(Mandatory = $false)]
    [String] $ActionGroupLocation = "global",  # Location for Action Group (usually 'global')

    # Alert Parameters
    [Parameter(Mandatory = $true)]
    [String] $AlertDescription,
    [Parameter(Mandatory = $true)]
    [int] $AlertSeverity,
    [Parameter(Mandatory = $true)]
    [String] $TargetResourceRegion,  # e.g. "eastus2"
    [Parameter(Mandatory = $true)]
    [String] $PipelineNameFilter,    # e.g. "*main*"
    [Parameter(Mandatory = $true)]
    [String[]] $FailureTypes,        # e.g. "UserError","SystemError","BadGateway"

    # Metric Configuration
    [Parameter(Mandatory = $true)]
    [String] $MetricName,            # e.g. "PipelineFailedRuns"
    [Parameter(Mandatory = $true)]
    [String] $MetricNamespace,       # e.g. "Microsoft.DataFactory/factories"
    [Parameter(Mandatory = $true)]
    [ValidateSet("Average","Minimum","Maximum","Total","Last")]
    [String] $TimeAggregation,       # e.g. "Total"
    [Parameter(Mandatory = $true)]
    [ValidateSet("GreaterThan","GreaterThanOrEqual","LessThan","LessThanOrEqual","Equal")]
    [String] $Operator,              # e.g. "GreaterThan"
    [Parameter(Mandatory = $true)]
    [int] $Threshold,                # e.g. 0
    [Parameter(Mandatory = $true)]
    [TimeSpan] $WindowSize,          # e.g. 01:00:00
    [Parameter(Mandatory = $true)]
    [TimeSpan] $Frequency            # e.g. 01:00:00
)


# Construct Action Group Name
$actionGroupName = "AC-$DataFactoryName"
Write-Host "Action Group Name: $actionGroupName"

# Build Email Receivers
$receivers = [System.Collections.ArrayList]@()
if ($Emails -and $EmailUserNames -and ($Emails.Count -eq $EmailUserNames.Count))
{
    for ($i=0; $i -lt $Emails.Count; $i++)
    {
        $emailReceiver = New-AzActionGroupEmailReceiverObject `
            -Name $EmailUserNames[$i] `
            -EmailAddress $Emails[$i]
        $null = $receivers.Add($emailReceiver)
    }
}
elseif (($Emails.Count -ne $EmailUserNames.Count) -and $Emails.Count -gt 0)
{
    Write-Warning "The number of Emails provided does not match the number of EmailUserNames. No email receivers will be added."
}

# Create/Update the Action Group
Write-Host "Creating/Updating Action Group..."
New-AzActionGroup `
    -Name $actionGroupName `
    -ResourceGroupName $ResourceGroupName `
    -ShortName $ShortName `
    -Location $ActionGroupLocation `
    -EmailReceiver $receivers

# Construct Alert Name
$alertName = "Alert-$DataFactoryName"
Write-Host "Alert Name: $alertName"

# Gather Pipelines that match the provided filter
Write-Host "Retrieving pipelines in Data Factory '$DataFactoryName' matching '$PipelineNameFilter'..."
$pList = @()
$pipelines = Get-AzDataFactoryV2Pipeline `
    -DataFactoryName $DataFactoryName `
    -ResourceGroupName $ResourceGroupName |
    Where-Object { $_.Name -like $PipelineNameFilter }

$pList = $pipelines.Name  # Collect pipeline names that matched

# Define Dimension Selections
Write-Host "Creating dimension selections for failure types and pipelines..."
$dimError = New-AzMetricAlertRuleV2DimensionSelection `
    -DimensionName FailureType `
    -ValuesToInclude $FailureTypes

$dimPipe = New-AzMetricAlertRuleV2DimensionSelection `
    -DimensionName Name `
    -ValuesToInclude $pList

# Define the Alert Condition
Write-Host "Creating alert condition..."
$condition = New-AzMetricAlertRuleV2Criteria `
    -MetricName $MetricName `
    -MetricNameSpace $MetricNamespace `
    -TimeAggregation $TimeAggregation `
    -Operator $Operator `
    -Threshold $Threshold `
    -DimensionSelection $dimError, $dimPipe

# Retrieve Action Group
Write-Host "Retrieving Action Group Id..."
$actionGroup = Get-AzActionGroup -ResourceGroupName $ResourceGroupName |
    Where-Object { $_.Name -eq $actionGroupName }

if (!$actionGroup)
{
    Write-Error "Action Group '$actionGroupName' not found in Resource Group '$ResourceGroupName'. Exiting."
    return
}

# Retrieve Data Factory Resource to target
Write-Host "Retrieving target Data Factory '$DataFactoryName'..."
$targetDataFactory = Get-AzDataFactoryV2 `
    -ResourceGroupName $ResourceGroupName `
    -Name $DataFactoryName

# Create or Update the Metric Alert Rule
Write-Host "Adding/Updating Metric Alert Rule..."
Add-AzMetricAlertRuleV2 `
    -Name $alertName `
    -ResourceGroupName $ResourceGroupName `
    -WindowSize $WindowSize `
    -Frequency $Frequency `
    -TargetResourceScope $targetDataFactory.DataFactoryId `
    -TargetResourceType "Microsoft.DataFactory/factories" `
    -TargetResourceRegion $TargetResourceRegion `
    -Description $AlertDescription `
    -Severity $AlertSeverity `
    -ActionGroupId $actionGroup.Id `
    -Condition $condition

Write-Host "Alert rule creation/update completed."
