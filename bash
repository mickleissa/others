#!/bin/bash

# Set your variables (hardcoded for now, replace with actual values)
region="us-west-2"
cluster_arn="arn:aws:ecs:us-west-2:123456789012:cluster/dev-matterworx"
project_env="dev"
module_name="app"

echo "Starting ECS service update process..."
echo "Region: $region"
echo "Cluster ARN: $cluster_arn"
echo "Project Environment: $project_env"
echo "Module Name: $module_name"

# Function to get the latest task definition ARN
get_latest_task_def_arn() {
  echo "Retrieving the latest task definition ARN..."
  aws ecs list-task-definitions \
    --family-prefix "$project_env-$module_name-task" \
    --sort DESC \
    --status ACTIVE \
    --max-items 1 \
    --query "taskDefinitionArns[0]" \
    --output text
}

# Function to update the ECS service
update_service() {
  local task_def_arn=$1
  echo "Updating the ECS service with the latest task definition and forcing new deployment..."
  aws ecs update-service \
    --region "$region" \
    --cluster "$cluster_arn" \
    --service "$project_env-$module_name-service" \
    --task-definition "$task_def_arn" \
    --force-new-deployment
}

# Retrieve the latest task definition ARN
latest_task_def_arn=$(get_latest_task_def_arn)
if [ $? -ne 0 ]; then
  echo "Error: Failed to retrieve the latest task definition ARN"
  echo "AWS CLI Output: $latest_task_def_arn"
  exit 1
fi

# Check if the latest_task_def_arn is empty
if [ -z "$latest_task_def_arn" ]; then
  echo "Error: No active task definitions found for $project_env-$module_name-task"
  exit 1
fi

echo "Latest task definition ARN retrieved: $latest_task_def_arn"

# Extract the task definition family name and revision (remove "arn:aws:ecs:region:account-id:task-definition/")
cleaned_task_def_arn=$(basename "$latest_task_def_arn")

# Try to update the ECS service up to 2 times
attempt=1
max_attempts=2
while [ $attempt -le $max_attempts ]; do
  update_output=$(update_service "$cleaned_task_def_arn")
  if [ $? -eq 0 ]; then
    echo "ECS service updated successfully to task definition $cleaned_task_def_arn on attempt $attempt"
    exit 0
  else
    echo "Error: Failed to update the ECS service on attempt $attempt"
    echo "AWS CLI Output: $update_output"
  fi
  attempt=$((attempt + 1))
done

# If we reach here, both attempts failed
echo "Error: Failed to update the ECS service after $max_attempts attempts"
exit 1
