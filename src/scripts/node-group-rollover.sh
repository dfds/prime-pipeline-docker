#!/bin/bash

# Check if eksctl and aws are installed
command -v eksctl >/dev/null 2>&1 || { echo >&2 "eksctl is required but not installed. Aborting."; exit 1; }
command -v aws >/dev/null 2>&1 || { echo >&2 "aws CLI is required but not installed. Aborting."; exit 1; }

# Check if cluster name and managed node group arguments are provided
if [ $# -lt 2 ]; then
  echo "Usage: $0 <cluster-name> <managed-node-group-1> [<managed-node-group-2> ...]"
  exit 1
fi

# Extract the script path to include other scripts
script_path=$(dirname "$(realpath -s "$0")")

# Extract the cluster name and managed node groups from the arguments
cluster_name=$1
shift
node_groups=$@

function wait_for_cluster() {
    # Wait for all node groups to be active
    $script_path/wait-for-ngs.sh $cluster_name

    # Wait for all auto scaling groups to not have all instances in service
    $script_path/wait-for-asgs.sh $cluster_name
}

# Wait for outstanding updates
wait_for_cluster

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

# Wait for scale up
wait_for_cluster

# Scale down each managed node group to half the maximum capacity (rounded up)
for node_group in $node_groups; do
  echo "Scaling down $node_group to half the maximum capacity..."
  max_nodes=$(aws eks describe-nodegroup --cluster-name $cluster_name --nodegroup-name $node_group --query "nodegroup.scalingConfig.maxSize" --output text)
  target_nodes=$((($max_nodes + 1) / 2))
  eksctl scale nodegroup --cluster=$cluster_name --name=$node_group --nodes=$target_nodes
done

# Wait for scale down
wait_for_cluster
