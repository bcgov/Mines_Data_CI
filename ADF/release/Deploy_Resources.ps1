# Script to replace environment variables and deploy resources to Azure Data Factory

# Usage: .\Deploy_Resources.ps1 [source_prefix] [target_prefix]
# source_prefix: the prefix to be replaced in JSON files (default: dev)
# target_prefix: the new prefix to be replaced with (default: tst)

param (
    [string]$SourceResourceGroupName = "",
    [string]$SourceDataFactoryName = "",
    [string]$TargetResourceGroupName = "",
    [string]$TargetDataFactoryName = "",
    [string]$TargetSubscription = "",
    [string]$source_prefix = "",
    [string]$target_prefix = "",
    [string]$trigger_action = "stop"
)

# Exit on error
$ErrorActionPreference = "Stop"

# Validate input parameters
Write-Output '---Validating input parameters---'
Write-Output $SourceResourceGroupName
Write-Output $SourceDataFactoryName
Write-Output $TargetResourceGroupName
Write-Output $TargetDataFactoryName
Write-Output $TargetSubscription
Write-Output $source_prefix
Write-Output $target_prefix
Write-Output '---done validation---'

# Function to extract properties section from JSON file
function Get-Properties {
    param (
        [string]$inputFilePath,
        [string]$outputFilePath
    )
    
    $jsonContent = Get-Content -Raw -Path $inputFilePath | ConvertFrom-Json
    $properties = $jsonContent.properties | ConvertTo-Json -Depth 100
    Set-Content -Path $outputFilePath -Value $properties
}

# Navigate to the artifact directory where files are stored
az account set --subscription $TargetSubscription
# Enable download of az datafactory cli
az config set extension.use_dynamic_install=yes_without_prompt

Push-Location "Artifacts/code"
$Artifact_Directory = Get-Location

# Replace source_prefix with target_prefix in JSON files
Write-Output "---Replacing environment $source_prefix to $target_prefix---"
$count = Get-ChildItem -Recurse -Filter *.json | ForEach-Object { 
    (Get-Content $_.FullName) -replace $source_prefix, $target_prefix | Set-Content $_.FullName 
} | Measure-Object | Select-Object -ExpandProperty Count
Write-Output "$count environment references were replaced."

# Define paths for different types of artifacts
$linkedServicePath = "$Artifact_Directory/linkedService"
$datasetPath = "$Artifact_Directory/dataset"
$pipelinePath = "$Artifact_Directory/pipeline"
$triggerPath = "$Artifact_Directory/trigger"

# Get a list of all JSON files in each directory
$linkedServiceJson = Get-ChildItem $linkedServicePath -Filter *.json -ErrorAction SilentlyContinue
$datasetJson = Get-ChildItem $datasetPath -Filter *.json -ErrorAction SilentlyContinue
$pipelineJson = Get-ChildItem $pipelinePath -Filter *.json -ErrorAction SilentlyContinue
$triggerJson = Get-ChildItem $triggerPath -Filter *.json -ErrorAction SilentlyContinue

# Deploy linked services
if ($linkedServiceJson) {
    foreach ($linkedServiceFile in $linkedServiceJson) {
        Write-Output "Deploying linked service $($linkedServiceFile.Name)"
        Get-Properties -inputFilePath $linkedServiceFile.FullName -outputFilePath $linkedServiceFile.FullName
        
        if (az datafactory linked-service show --resource-group $TargetResourceGroupName --factory-name $TargetDataFactoryName --name $linkedServiceFile.BaseName -ErrorAction SilentlyContinue) {
            Write-Output 'Updating linked service'
            az datafactory linked-service create --resource-group $TargetResourceGroupName --factory-name $TargetDataFactoryName --name $linkedServiceFile.BaseName --properties @"
$linkedServiceFile.FullName
"@
            if ($?) { Write-Output "Linked service update succeeded" } else { Write-Output "Linked service update failed with return code: $?" }
        } else {
            Write-Output 'Creating linked service'
            az datafactory linked-service create --resource-group $TargetResourceGroupName --factory-name $TargetDataFactoryName --name $linkedServiceFile.BaseName --properties @"
$linkedServiceFile.FullName
"@
            if ($?) { Write-Output "Linked service create succeeded" } else { Write-Output "Linked service create failed with return code: $?" }
        }
    }
}

# Deploy datasets
if ($datasetJson) {
    foreach ($datasetFile in $datasetJson) {
        Write-Output "Deploying dataset $($datasetFile.Name)"
        if (az datafactory dataset show --resource-group $TargetResourceGroupName --factory-name $TargetDataFactoryName --name $datasetFile.BaseName -ErrorAction SilentlyContinue) {
            Write-Output 'Updating dataset'
            az datafactory dataset create --resource-group $TargetResourceGroupName --factory-name $TargetDataFactoryName --name $datasetFile.BaseName --properties @"
$datasetFile.FullName
"@
            if ($?) { Write-Output "Dataset update succeeded" } else { Write-Output "Dataset update failed with return code: $?" }
        } else {
            Write-Output 'Creating dataset'
            az datafactory dataset create --resource-group $TargetResourceGroupName --factory-name $TargetDataFactoryName --name $datasetFile.BaseName --properties @"
$datasetFile.FullName
"@
            if ($?) { Write-Output "Dataset deployment succeeded" } else { Write-Output "Dataset creation failed with return code: $?" }
        }
    }
}

# Deploy pipelines
if ($pipelineJson) {
    foreach ($pipelineFile in $pipelineJson) {
        Write-Output "Deploying pipeline $($pipelineFile.Name)"
        if (az datafactory pipeline show --resource-group $TargetResourceGroupName --factory-name $TargetDataFactoryName --name $pipelineFile.BaseName -ErrorAction SilentlyContinue) {
            Write-Output 'Updating existing pipeline'
            az datafactory pipeline create --resource-group $TargetResourceGroupName --factory-name $TargetDataFactoryName --name $pipelineFile.BaseName --pipeline @"
$pipelineFile.FullName
"@
            if ($?) { Write-Output "Pipeline deployment succeeded" } else { Write-Output "Pipeline creation failed with return code: $?" }
        } else {
            Write-Output 'Creating new pipeline'
            az datafactory pipeline create --resource-group $TargetResourceGroupName --factory-name $TargetDataFactoryName --name $pipelineFile.BaseName --pipeline @"
$pipelineFile.FullName
"@
            if ($?) { Write-Output "Pipeline deployment succeeded" } else { Write-Output "Pipeline creation failed with return code: $?" }
        }
    }
}

# Deploy triggers
if ($triggerJson) {
    foreach ($triggerFile in $triggerJson) {
        Write-Output "Deploying trigger $($triggerFile.Name)"
        Get-Properties -inputFilePath $triggerFile.FullName -outputFilePath $triggerFile.FullName
        if (az datafactory trigger show --resource-group $TargetResourceGroupName --factory-name $TargetDataFactoryName --name $triggerFile.BaseName -ErrorAction SilentlyContinue) {
            Write-Output 'Updating existing trigger'
            az datafactory trigger stop --resource-group $TargetResourceGroupName --factory-name $TargetDataFactoryName --name $triggerFile.BaseName
            az datafactory trigger create --resource-group $TargetResourceGroupName --factory-name $TargetDataFactoryName --name $triggerFile.BaseName --properties @"
$triggerFile.FullName
"@
            az datafactory trigger $trigger_action --resource-group $TargetResourceGroupName --factory-name $TargetDataFactoryName --name $triggerFile.BaseName
            if ($?) { Write-Output "Trigger update succeeded and trigger started" } else { Write-Output "Trigger creation failed with return code: $?" }
        } else {
            az datafactory trigger create --resource-group $TargetResourceGroupName --factory-name $TargetDataFactoryName --name $triggerFile.BaseName --properties @"
$triggerFile.FullName
"@
            az datafactory trigger $trigger_action --resource-group $TargetResourceGroupName --factory-name $TargetDataFactoryName --name $triggerFile.BaseName
            if ($?) { Write-Output "Trigger deployment succeeded and trigger started" } else { Write-Output "Trigger creation failed with return code: $?" }
        }
    }
}

Pop-Location
