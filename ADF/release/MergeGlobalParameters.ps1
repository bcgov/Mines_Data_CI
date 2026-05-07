param (
    [string]$GeneratedFilePath,
    [string]$OverwriteFilePath
)

# Log paths
Write-Host "GeneratedFilePath: $GeneratedFilePath"
Write-Host "OverwriteFilePath: $OverwriteFilePath"

# Verify paths
if (-Not (Test-Path $GeneratedFilePath)) {
    Write-Error "GeneratedFilePath does not exist: $GeneratedFilePath"
    exit 1
}

if (-Not (Test-Path $OverwriteFilePath)) {
    Write-Warning "OverwriteFilePath does not exist, creating it: $OverwriteFilePath"
    New-Item -ItemType File -Path $OverwriteFilePath -Force
}

# Read the generated and overwrite files
$generatedParams = Get-Content -Path $GeneratedFilePath | ConvertFrom-Json
$overwriteParams = @{}

if ((Get-Content $OverwriteFilePath | Out-String).Trim()) {
    $overwriteParams = Get-Content -Path $OverwriteFilePath | ConvertFrom-Json
}

# Merge logic: Replace values from overwrite file and add missing keys
foreach ($key in $generatedParams.PSObject.Properties.Name) {
    if ($overwriteParams.PSObject.Properties[$key]) {
        # Replace existing key value from overwrite file
        $generatedParams.$key = $overwriteParams.$key
    } else {
        # Add missing key to overwrite file
        $overwriteParams | Add-Member -NotePropertyName $key -NotePropertyValue $generatedParams.$key
    }
}

# Write back updated generated file
$generatedParams | ConvertTo-Json -Depth 10 | Set-Content -Path $GeneratedFilePath

# Write back updated overwrite file
$overwriteParams | ConvertTo-Json -Depth 10 | Set-Content -Path $OverwriteFilePath

Write-Host "Merged overwrite parameters into '$GeneratedFilePath'. Missing keys added to '$OverwriteFilePath'."
