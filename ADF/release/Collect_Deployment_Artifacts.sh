#!/bin/bash

# Script to collect deployment artifacts for ADF CICD pipeline. This script will grab
# all the files generated in a specific commit add them to a staging folder 
# Now includes detection of deleted files with original directory structure
# and a manifest file for deleted items as comma-separated resource type and name,
# processed in order: triggers, pipelines, datasets, linkedservices

set -e

# Define directories and files
ARTIFACTS_DIR="../release/Artifacts"
MANIFEST_FILE="../release/Artifacts_Manifest.txt"
DELETED_DIR="../release/Artifacts/deleted"
DELETED_MANIFEST="$DELETED_DIR/Deleted_Manifest.txt"
TEMP_MANIFEST="/tmp/temp_deleted_manifest.txt"

# Remove existing Artifacts directory and manifest files
rm -rf "$ARTIFACTS_DIR"
rm -f "$MANIFEST_FILE"

# Create Artifacts and deleted directories
mkdir -p "$ARTIFACTS_DIR"
mkdir -p "$DELETED_DIR"

# Capture all files that have been added, modified, or deleted in the last commit
git diff --name-status HEAD~1 HEAD -- ../code/ > "$MANIFEST_FILE"

# Check if there are any changes
countOfChanges=$(wc -l < "$MANIFEST_FILE")
if [ "$countOfChanges" -eq "0" ]; then
  echo "No deployment artifacts found. Nothing to deploy. Exiting script."
  export DEPLOY_ARTIFACTS=0
  exit 0
fi

echo "Number of Changes Detected = $countOfChanges"
echo "---Moving to Staging Directory---"

# Process added/modified files first (no change needed here)
while IFS=$'\t' read -r status file; do
  parent_dir="$(dirname "$file")"
  if [[ "$status" == "A" || "$status" == "M" ]]; then
    echo "Staging file for release: $file"
    mkdir -p "$ARTIFACTS_DIR/${parent_dir}"
    cp -r "../$file" "$ARTIFACTS_DIR/${parent_dir}"
  fi
done < "$MANIFEST_FILE"

# Now handle deletions with specific order
echo "---Processing Deletions in Order: triggers, pipelines, datasets, linkedservices---"

# Create a temporary file to store deleted files with priority
> "$TEMP_MANIFEST"

# Assign priority and extract type and name
while IFS=$'\t' read -r status file; do
  if [ "$status" == "D" ]; then
    resource_name=$(basename "$file")
    if [[ "$file" =~ /trigger/ ]]; then
      priority=1  # Triggers first
      resource_type="trigger"
    elif [[ "$file" =~ /pipeline/ ]]; then
      priority=2  # Pipelines second
      resource_type="pipeline"
    elif [[ "$file" =~ /dataset/ ]]; then
      priority=3  # Datasets third
      resource_type="dataset"
    elif [[ "$file" =~ /linkedService/ ]]; then
      priority=4  # LinkedServices fourth
      resource_type="linkedService"
    else
      priority=5  # Anything else last
      resource_type="unknown"
    fi
    echo -e "$priority\t$resource_type,$resource_name" >> "$TEMP_MANIFEST"
  fi
done < "$MANIFEST_FILE"

# Sort by priority and write to final deleted manifest
sort -n "$TEMP_MANIFEST" | cut -f2- > "$DELETED_MANIFEST"

# Process sorted deletions (keeping directory structure)
while IFS=$'\t' read -r status file; do
  if [ "$status" == "D" ]; then
    parent_dir="$(dirname "$file")"
    echo "Recording deleted file: $file"
    mkdir -p "$DELETED_DIR/${parent_dir}"
    echo "$file" > "$DELETED_DIR/${parent_dir}/$(basename "$file")"
  fi
done < "$MANIFEST_FILE"

# Clean up temporary file
rm -f "$TEMP_MANIFEST"

export DEPLOY_ARTIFACTS=1