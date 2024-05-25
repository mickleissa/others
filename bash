#!/bin/bash

# Set your variables
region=$(region)
cluster_arn=$(cluster_arn)
project_env=$(project_env)
module_name=$(module_name)

# Get the last running task definition ARN
last_task_def_arn=$(aws ecs describe-services \
  --region $region \
  --cluster $cluster_arn/$project_env-matterworx \
  --services $project_env-$module_name-service \
  --query "services[0].taskDefinition" \
  --output text)

# Check if the describe-services command was successful
if [ $? -ne 0 ]; then
  echo "Error: Failed to retrieve the last running task definition ARN"
  exit 1
fi

# Update the ECS service with the last running task definition
update_output=$(aws ecs update-service \
  --region $region \
  --cluster $cluster_arn/$project_env-matterworx \
  --service $project_env-$module_name-service \
  --task-definition $last_task_def_arn)

# Check if the update-service command was successful
if [ $? -ne 0 ]; then
  echo "Error: Failed to update the ECS service"
  exit 1
fi

echo "ECS service updated successfully"
