#!/bin/bash

# replace environment variables
# Usage: bash Deploy_Resources.sh [source_prefix] [target_prefix]
# source_prefix: the prefix to be replaced in JSON files
# target_prefix: the new prefix to be replaced with


set -e



SourceResourceGroupName="${1}"
SourceDataFactoryName="${2}"
TargetResourceGroupName="${3}"
TargetDataFactoryName="${4}"
TargetSubscription="${5}"
source_prefix="${6}"
target_prefix="${7}"
trigger_action="${8:-stop}"
additional_replacement_source="${9}"
additional_replacement_target="${10}"
SourceSubscription="${11}"

# validate input parameters #
echo '---Validating input parameters---' 
echo $SourceResourceGroupName
echo $SourceDataFactoryName
echo $TargetResourceGroupName
echo $TargetDataFactoryName
echo $TargetSubscription
echo $source_prefix
echo $target_prefix
echo $additional_replacement_source
echo $additional_replacement_target
echo '---done validation---'



############################################################################
#### Due to bug with ADF CLI need to parse properties object on trigger ####
#
#
get_trigger_properties() {
    local input_file_path="$1"
    local output_file_path="$2"
    
    # Read the JSON file
    local json_content
    json_content=$(cat "$input_file_path")
    
    # Convert JSON content to a Bash variable
    local properties
    properties=$(echo "$json_content" | jq -r '.properties')
    
    # Save the 'properties' section as a new JSON file
    echo "$properties" > "$output_file_path"
}
#
############################################################################



# Navigate to the artifact directory where files are stored
az account set --subscription $TargetSubscription
# enable download of az datafactory cli #
az config set extension.use_dynamic_install=yes_without_prompt

pwd
ls /home/vsts/work/1/s/release
cd Artifacts/code
Artifact_Directory=$(pwd)

# Replace source_prefix with target_prefix in JSON files

echo "---Replacing environment $source_prefix  to $target_prefix ---"
count=$(find "$(pwd)" -type f -name "*.json" -print0 | xargs -0 sed -n "s/$source_prefix/$target_prefix/gp" | wc -l)
find "$(pwd)" -type f -name "*.json" -print0 | xargs -0 sed -i "s/$source_prefix/$target_prefix/g"
countadditional=$(find "$(pwd)" -type f -name "*.json" -print0 | xargs -0 sed -n "s/$additional_replacement_source/$additional_replacement_target/gp" | wc -l)
find "$(pwd)" -type f -name "*.json" -print0 | xargs -0 sed -i "s/$additional_replacement_source/$additional_replacement_target/g"
#replace inner subscriptions
find "$(pwd)" -type f -name "*.json" -print0 | xargs -0 sed -i "s/$SourceSubscription/$TargetSubscription/g"
echo "$count environment references were replaced."
echo "$countadditional additional references were replaced."


# Create the directory paths for linked service, dataset, pipeline, and trigger files
linkedServicePath="$Artifact_Directory/linkedService"
datasetPath="$Artifact_Directory/dataset"
pipelinePath="$Artifact_Directory/pipeline"
triggerPath="$Artifact_Directory/trigger"



# Get a list of all JSON files in each directory
linkedServiceJson=$(ls $linkedServicePath 2>/dev/null || echo "")
datasetJson=$(ls $datasetPath 2>/dev/null || echo "")
pipelineJson=$(ls $pipelinePath 2>/dev/null || echo "")
triggerJson=$(ls $triggerPath 2>/dev/null || echo "")

# Create linked services in the Azure Data Factory for each JSON file in the linked service directory
if [ -n "$linkedServiceJson" ]; then
  for linkedServiceFile in $linkedServiceJson; do
  
    echo "Deploying linked service $linkedServiceFile"
      # Date of change 2023-07-18 #
      # Due to bug with ADF CLI its not able to deploy using arm template so we need to extract properties object #
      get_trigger_properties "$linkedServicePath/$linkedServiceFile" "$linkedServicePath/$linkedServiceFile"

    # check if linked service exists to determine if create or update is needed
    if az datafactory linked-service show --resource-group $TargetResourceGroupName --factory-name $TargetDataFactoryName --name $(basename $linkedServiceFile .json) &> /dev/null; then
      
      echo 'updating linked service'
      az datafactory linked-service create --resource-group $TargetResourceGroupName --factory-name $TargetDataFactoryName --name $(basename $linkedServiceFile .json) --properties @"$linkedServicePath/$linkedServiceFile" > /dev/null

      if [[ "$?" -eq 0 ]]; then
        echo "linked service update succeeded"
      else
        echo "linked service update failed with return code: $?"
      fi
    
    else

      echo 'creating linked service'
      az datafactory linked-service create --resource-group $TargetResourceGroupName --factory-name $TargetDataFactoryName --name $(basename $linkedServiceFile .json) --properties @"$linkedServicePath/$linkedServiceFile" > /dev/null

      if [[ "$?" -eq 0 ]]; then
        echo "linked service create succeeded"
      else
        echo "linked service create failed with return code: $?"
      fi

    fi
  done
fi

# Create datasets in the Azure Data Factory for each JSON file in the dataset directory
if [ -n "$datasetJson" ]; then
  for datasetFile in $datasetJson; do
    echo "Deploying dataset $datasetFile"
    get_trigger_properties "$datasetPath/$datasetFile" "$datasetPath/$datasetFile"

    # check if dataset exists to determine if create or update is needed
    if az datafactory dataset show --resource-group $TargetResourceGroupName --factory-name $TargetDataFactoryName --name $(basename $datasetFile .json) &> /dev/null; then

      echo 'updating dataset'
      az datafactory dataset create --resource-group $TargetResourceGroupName --factory-name $TargetDataFactoryName --name $(basename $datasetFile .json) --properties @"$datasetPath/$datasetFile" > /dev/null

      if [[ "$?" -eq 0 ]]; then
        echo "dataset update succeeded"
      else
        echo "dataset update failed with return code: $?"
      fi
  
    else

      echo 'creating dataset'
      az datafactory dataset create --resource-group $TargetResourceGroupName --factory-name $TargetDataFactoryName --name $(basename $datasetFile .json) --properties @"$datasetPath/$datasetFile" > /dev/null

      if [[ "$?" -eq 0 ]]; then
        echo "dataset deployment succeeded"
      else
        echo "dataset creation failed with return code: $?"
      fi
      
    fi
  done
fi

# Create pipelines in the Azure Data Factory for each JSON file in the pipeline directory
if [ -n "$pipelineJson" ]; then
  for pipelineFile in $pipelineJson; do
    echo "Deploying pipeline $pipelineFile"

    if az datafactory pipeline show --resource-group $TargetResourceGroupName --factory-name $TargetDataFactoryName --name $(basename $pipelineFile .json) &> /dev/null; then

      echo 'updating existing pipeline'
      az datafactory pipeline create --resource-group $TargetResourceGroupName --factory-name $TargetDataFactoryName --name $(basename $pipelineFile .json) --pipeline @"$pipelinePath/$pipelineFile" > /dev/null

      # capture status
      if [[ "$?" -eq 0 ]]; then
        echo "Pipeline deployment succeeded"
      else
        echo "Pipeline creation failed with return code: $?"
      fi
      
    else 
      echo 'creating new pipeline'
      az datafactory pipeline create --resource-group $TargetResourceGroupName --factory-name $TargetDataFactoryName --name $(basename $pipelineFile .json) --pipeline @"$pipelinePath/$pipelineFile" > /dev/null

       # capture status
      if [[ "$?" -eq 0 ]]; then
        echo "Pipeline deployment succeeded"
      else
        echo "Pipeline creation failed with return code: $?"
      fi

    fi
  done
fi

# Create triggers in the Azure Data Factory for each JSON file in the trigger directory
if [ -n "$triggerJson" ]; then
  for triggerFile in $triggerJson; do
    echo "Deploying trigger $triggerFile"

    if az datafactory trigger show --resource-group $TargetResourceGroupName --factory-name $TargetDataFactoryName --name $(basename $triggerFile .json) &> /dev/null; then

      echo 'updating existing trigger'

      # Date of change 2023-07-18 #
      # Due to bug with ADF CLI its not able to deploy using arm template so we need to extract properties object #
      get_trigger_properties "$triggerPath/$triggerFile" "$triggerPath/$triggerFile"
      #
      az datafactory trigger stop --resource-group $TargetResourceGroupName --factory-name $TargetDataFactoryName --name $(basename $triggerFile .json)
      az datafactory trigger create --resource-group $TargetResourceGroupName --factory-name $TargetDataFactoryName --name $(basename $triggerFile .json) --properties @"$triggerPath/$triggerFile" > /dev/null
      az datafactory trigger $trigger_action --resource-group $TargetResourceGroupName --factory-name $TargetDataFactoryName --name $(basename $triggerFile .json)
      
      # team wants trigger deployments to be done in stopped state disabling the start for now wed 2023 07 27
      #az datafactory trigger start --resource-group $TargetResourceGroupName --factory-name $TargetDataFactoryName --name $(basename $triggerFile .json)
      
       # capture status
      if [[ "$?" -eq 0 ]]; then
        echo "trigger update succeeded and trigger started"
      else
        echo "trigger creation failed with return code: $?"
      fi

    else 
    
      get_trigger_properties "$triggerPath/$triggerFile" "$triggerPath/$triggerFile"
      az datafactory trigger create --resource-group $TargetResourceGroupName --factory-name $TargetDataFactoryName --name $(basename $triggerFile .json) --properties @"$triggerPath/$triggerFile" > /dev/null
      az datafactory trigger $trigger_action --resource-group $TargetResourceGroupName --factory-name $TargetDataFactoryName --name $(basename $triggerFile .json)
      # team wants trigger deployments to be done in stopped state disabling the start for now wed  2023 07 27
      #az datafactory trigger start --resource-group $TargetResourceGroupName --factory-name $TargetDataFactoryName --name $(basename $triggerFile .json)
      
       # capture status
      if [[ "$?" -eq 0 ]]; then
        echo "trigger deployment succeeded and trigger started"
      else
        echo "trigger creation failed with return code: $?"
      fi


    fi
  done
  
fi

cd ../..
