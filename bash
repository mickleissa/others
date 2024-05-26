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

# Get the latest task definition ARN
echo "Retrieving the latest task definition ARN..."
latest_task_def_arn=$(aws ecs list-task-definitions \
  --family-prefix $project_env-$module_name-task \
  --sort DESC \
  --status ACTIVE \
  --max-items 1 \
  --query "taskDefinitionArns[0]" \
  --output text)

# Check if the list-task-definitions command was successful
if [ $? -ne 0 ]; then
  echo "Error: Failed to retrieve the latest task definition ARN"
  exit 1
fi

# Check if the latest_task_def_arn is empty
if [ -z "$latest_task_def_arn" ]; then
  echo "Error: No active task definitions found for $project_env-$module_name-task"
  exit 1
fi

echo "Latest task definition ARN retrieved: $latest_task_def_arn"

# Function to update the ECS service
update_service() {
  echo "Updating the ECS service with the latest task definition and forcing new deployment..."
  update_output=$(aws ecs update-service \
    --region $region \
    --cluster $cluster_arn \
    --service $project_env-$module_name-service \
    --task-definition $latest_task_def_arn \
    --force-new-deployment 2>&1)
  
  return $?
}

# Try to update the ECS service up to 2 times
attempt=1
max_attempts=2
while [ $attempt -le $max_attempts ]; do
  update_service
  if [ $? -eq 0 ]; then
    echo "ECS service updated successfully to task definition $latest_task_def_arn on attempt $attempt"
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
