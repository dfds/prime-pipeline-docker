#!/bin/bash

# Check if eksctl and aws are installed
command -v eksctl >/dev/null 2>&1 || { echo >&2 "eksctl is required but not installed. Aborting."; exit 1; }
command -v aws >/dev/null 2>&1 || { echo >&2 "aws CLI is required but not installed. Aborting."; exit 1; }

# Check if cluster name and managed node group arguments are provided
if [ $# -lt 2 ]; then
  echo "Usage: $0 <cluster-name> <managed-node-group-1> [<managed-node-group-2> ...]"
  exit 1
fi

# Extract the cluster name and managed node groups from the arguments
cluster_name=$1
shift
node_groups=$@

# Print out the cluster name and node groups
echo "Scaling the following managed node groups in the $cluster_name cluster:"
for node_group in $node_groups; do
  echo "- $node_group"
done

# Scale up each managed node group to maximum capacity using eksctl
for node_group in $node_groups; do
  echo "Scaling up $node_group to maximum capacity..."
  max_nodes=$(aws eks describe-nodegroup --cluster-name $cluster_name --nodegroup-name $node_group --query "nodegroup.scalingConfig.maxSize" --output text)
  eksctl scale nodegroup --cluster=$cluster_name --name=$node_group --nodes=$max_nodes
done

# Wait for all Node Groups to be active
echo "Waiting for all Node Groups to be active..."
./bin/wait-for-ngs.sh $cluster_name

# Wait for all Auto Scaling Groups to not have all instances in service
echo "Waiting for all Auto Scaling Groups to not all instances in service..."
./bin/wait-for-asgs.sh $cluster_name

# Scale down each managed node group to half the maximum capacity (rounded up)
for node_group in $node_groups; do
  echo "Scaling down $node_group to half the maximum capacity..."
  max_nodes=$(aws eks describe-nodegroup --cluster-name $cluster_name --nodegroup-name $node_group --query "nodegroup.scalingConfig.maxSize" --output text)
  target_nodes=$((($max_nodes + 1) / 2))
  eksctl scale nodegroup --cluster=$cluster_name --name=$node_group --nodes=$target_nodes
done

# Wait for all Node Groups to be active
echo "Waiting for all Node Groups to be active..."
./bin/wait-for-ngs.sh $cluster_name

# Wait for all Auto Scaling Groups to not have all instances in service
echo "Waiting for all Auto Scaling Groups to not all instances in service..."
./bin/wait-for-asgs.sh $cluster_name
