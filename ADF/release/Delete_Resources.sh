#!/bin/bash

# Script to delete Azure Data Factory resources specified in Deleted_Manifest.txt
# Usage: bash Delete_Resources.sh [--dry-run] [SourceResourceGroupName] [SourceDataFactoryName] [TargetResourceGroupName] [TargetDataFactoryName] [TargetSubscription]
# Resources are deleted in order: triggers, pipelines, datasets, linkedservices
# --dry-run: Only prints what would be deleted without executing commands
# Resource names are stripped of extensions and wrapped in triple quotes to handle spaces
# Logging reflects the resource name without extension

set -e

# Default environment variables
DRY_RUN=false
SourceResourceGroupName=""
SourceDataFactoryName=""
TargetResourceGroupName=""
TargetDataFactoryName=""
TargetSubscription=""
SourceSubscription=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    *)
      SourceResourceGroupName="${1}"
      SourceDataFactoryName="${2}"
      TargetResourceGroupName="${3}"
      TargetDataFactoryName="${4}"
      TargetSubscription="${5}"
      SourceSubscription="${6}"
      shift $(( $# > 6 ? 6 : $# ))
      ;;
  esac
done

# Validate input parameters
echo '---Validating input parameters---' 
echo "SourceResourceGroupName: $SourceResourceGroupName"
echo "SourceDataFactoryName: $SourceDataFactoryName"
echo "TargetResourceGroupName: $TargetResourceGroupName"
echo "TargetDataFactoryName: $TargetDataFactoryName"
echo "TargetSubscription: $TargetSubscription"
echo "SourceSubscription: $SourceSubscription"
echo "Dry Run: $DRY_RUN"
echo '---Done validation---'

# Set the subscription (skip in dry run)
if [ "$DRY_RUN" = false ]; then
  az account set --subscription "$TargetSubscription"
  # Enable dynamic install of az datafactory CLI
  az config set extension.use_dynamic_install=yes_without_prompt
fi

# Navigate to the artifact directory
cd Artifacts || { echo "Artifacts directory not found"; exit 1; }
DELETED_DIR="$PWD/deleted"
DELETED_MANIFEST="$DELETED_DIR/Deleted_Manifest.txt"

# Check if the deleted manifest exists
if [ ! -f "$DELETED_MANIFEST" ]; then
  echo "No Deleted_Manifest.txt found in $DELETED_DIR. Nothing to delete. Exiting script."
  exit 0
fi

# Count the number of deletions
countOfDeletions=$(wc -l < "$DELETED_MANIFEST")
if [ "$countOfDeletions" -eq "0" ]; then
  echo "Deleted_Manifest.txt is empty. Nothing to delete. Exiting script."
  exit 0
fi

echo "Number of Resources to Delete = $countOfDeletions"
echo "---Processing Deletions in Order: triggers, pipelines, datasets, linkedservices---"

# Process deletions in the specified order
while IFS=',' read -r resource_type resource_name; do
  # Trim whitespace from resource_type and resource_name
  resource_type=$(echo "$resource_type" | xargs)
  resource_name=$(echo "$resource_name" | xargs)
  
  # Extract the resource name without extension and wrap in triple quotes for az commands
  resource_name_no_ext="\"\"\"$(basename "$resource_name" .json)\"\"\""
  # For logging, strip quotes to show the clean name
  resource_name_clean=$(basename "$resource_name" .json)

  case "$resource_type" in
    trigger)
      echo "Deleting trigger: $resource_name_clean"
      if [ "$DRY_RUN" = true ]; then
        echo "[Dry Run] Would delete trigger: $resource_name_clean"
      else
        if az datafactory trigger show --resource-group "$TargetResourceGroupName" --factory-name "$TargetDataFactoryName" --name $resource_name_no_ext &> /dev/null; then
          az datafactory trigger stop --resource-group "$TargetResourceGroupName" --factory-name "$TargetDataFactoryName" --name $resource_name_no_ext > /dev/null 2>&1
          az datafactory trigger delete --resource-group "$TargetResourceGroupName" --factory-name "$TargetDataFactoryName" --name $resource_name_no_ext --yes > /dev/null
          if [[ "$?" -eq 0 ]]; then
            echo "Trigger $resource_name_clean deleted successfully"
          else
            echo "Failed to delete trigger $resource_name_clean with return code: $?"
          fi
        else
          echo "Trigger $resource_name_clean does not exist, skipping deletion"
        fi
      fi
      ;;
    pipeline)
      echo "Deleting pipeline: $resource_name_clean"
      if [ "$DRY_RUN" = true ]; then
        echo "[Dry Run] Would delete pipeline: $resource_name_clean"
      else
        if az datafactory pipeline show --resource-group "$TargetResourceGroupName" --factory-name "$TargetDataFactoryName" --name $resource_name_no_ext &> /dev/null; then
          az datafactory pipeline delete --resource-group "$TargetResourceGroupName" --factory-name "$TargetDataFactoryName" --name $resource_name_no_ext --yes > /dev/null
          if [[ "$?" -eq 0 ]]; then
            echo "Pipeline $resource_name_clean deleted successfully"
          else
            echo "Failed to delete pipeline $resource_name_clean with return code: $?"
          fi
        else
          echo "Pipeline $resource_name_clean does not exist, skipping deletion"
        fi
      fi
      ;;
    dataset)
      echo "Deleting dataset: $resource_name_clean"
      if [ "$DRY_RUN" = true ]; then
        echo "[Dry Run] Would delete dataset: $resource_name_clean"
      else
        if az datafactory dataset show --resource-group "$TargetResourceGroupName" --factory-name "$TargetDataFactoryName" --name $resource_name_no_ext &> /dev/null; then
          az datafactory dataset delete --resource-group "$TargetResourceGroupName" --factory-name "$TargetDataFactoryName" --name $resource_name_no_ext --yes > /dev/null
          if [[ "$?" -eq 0 ]]; then
            echo "Dataset $resource_name_clean deleted successfully"
          else
            echo "Failed to delete dataset $resource_name_clean with return code: $?"
          fi
        else
          echo "Dataset $resource_name_clean does not exist, skipping deletion"
        fi
      fi
      ;;
    linkedService)
      echo "Deleting linked service: $resource_name_clean"
      if [ "$DRY_RUN" = true ]; then
        echo "[Dry Run] Would delete linked service: $resource_name_clean"
      else
        if az datafactory linked-service show --resource-group "$TargetResourceGroupName" --factory-name "$TargetDataFactoryName" --name $resource_name_no_ext &> /dev/null; then
          az datafactory linked-service delete --resource-group "$TargetResourceGroupName" --factory-name "$TargetDataFactoryName" --name $resource_name_no_ext --yes > /dev/null
          if [[ "$?" -eq 0 ]]; then
            echo "Linked service $resource_name_clean deleted successfully"
          else
            echo "Failed to delete linked service $resource_name_clean with return code: $?"
          fi
        else
          echo "Linked service $resource_name_clean does not exist, skipping deletion"
        fi
      fi
      ;;
    *)
      echo "Unknown resource type '$resource_type' for $resource_name, skipping"
      ;;
  esac
done < "$DELETED_MANIFEST"

echo "---Deletion Process Completed---"
cd ..
