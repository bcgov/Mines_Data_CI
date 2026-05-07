#!/bin/bash

replace_env_strings() {
  local dictionary_file="$1"
  local environment="$2"
  local object_type="$3"
  local target_folder="$4"

  # Check if jq is installed
  if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install jq to use this function."
    return 1
  fi

  # Validate dictionary file existence
  if [[ ! -f "$dictionary_file" ]]; then
    echo "Error: Dictionary file '${dictionary_file}' does not exist."
    return 1
  fi

  # Validate environment
  if ! jq -e ".${environment}" "$dictionary_file" > /dev/null; then
    echo "Error: Environment '${environment}' not found in the dictionary."
    return 1
  fi

  # Validate object_type
  if ! jq -e ".${environment}.${object_type}" "$dictionary_file" > /dev/null; then
    echo "Error: Object type '${object_type}' not found under environment '${environment}' in the dictionary."
    return 1
  fi

  # Validate target_folder
  if [[ ! -d "$target_folder" ]]; then
    echo "Error: Target folder '${target_folder}' does not exist or is not a directory."
    return 1
  fi

  # Extract all before and after pairs
  local replacements
  replacements=$(jq -c ".${environment}.${object_type}[]" "$dictionary_file")

  if [[ -z "$replacements" ]]; then
    echo "Error: No replacement pairs found for environment '${environment}' and object type '${object_type}'."
    return 1
  fi

  # Find all .json files in target_folder
  mapfile -d $'\0' json_files < <(find "$target_folder" -type f -name "*.json" -print0)

  if [[ ${#json_files[@]} -eq 0 ]]; then
    echo "No .json files found in '${target_folder}'."
    return 1
  fi

  # Iterate through each replacement pair
  while IFS= read -r replacement; do
    local before after

    before=$(echo "$replacement" | jq -r ".before")
    after=$(echo "$replacement" | jq -r ".after")

    # Check if before and after are valid
    if [[ -z "$before" || "$before" == "null" || -z "$after" || "$after" == "null" ]]; then
      echo "Warning: 'before' or 'after' value is missing or null. Skipping this pair."
      continue
    fi

    echo "--- Replacing '${before}' with '${after}' in folder '${target_folder}' ---"

    # Initialize occurrence counter
    local total_count=0

    # Iterate through each JSON file
    for file in "${json_files[@]}"; do
      # Count occurrences in the current file
      local count
      count=$(grep -oF "$before" "$file" | wc -l)

      if [[ "$count" -gt 0 ]]; then
        # Perform the replacement with backup (.bak)
        # Using '|' as delimiter to handle URLs and paths
        sed -i.bak "s|${before}|${after}|g" "$file"

        echo "Replaced $count occurrence(s) in '$file'."

        # Update total count
        total_count=$((total_count + count))
      fi
    done

    echo "$total_count occurrence(s) of '${before}' were replaced with '${after}'."

  done <<< "$replacements"

  echo "All replacements completed."
}



# Usage: replace_env_strings <dictionary_file> <environment> <object_type> <target_folder>
# Example: replace_env_strings "../ADF/code/dictionary.json" "dev" "linkedServiceJson" "./ADF/code/linkedService"