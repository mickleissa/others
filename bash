#!/bin/bash

# Set your variables
region=$(region)
cluster_arn=$(cluster_arn)
project_env=$(project_env)
module_name=$(module_name)

latest_task_def_arn=$(aws ecs list-task-definitions \
  --family-prefix $project_env-$module_name-task \
  --sort DESC \
  --status ACTIVE \
  --max-items 1 \
  --query "taskDefinitionArns[0]" \
  --output text)

# Check if the list-task-definitions command was successful
if [ $? -ne 0 ] || [ -z "$latest_task_def_arn" ]; then
  echo "Error: Failed to retrieve the latest task definition ARN"
  exit 1
fi

# Update the ECS service with the latest task definition
update_output=$(aws ecs update-service \
  --region $region \
  --cluster $cluster_arn/$project_env-matterworx \
  --service $project_env-$module_name-service \
  --task-definition $latest_task_def_arn)

# Check if the update-service command was successful
if [ $? -ne 0 ]; then
  echo "Error: Failed to update the ECS service"
  exit 1
fi

echo "ECS service updated successfully to task definition $latest_task_def_arn"
