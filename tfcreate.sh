#!/bin/bash
# Usage: ./tfcreate.sh k8s-cluster-name

[ -z "$1" ] && clusterName="tfTest-cluster" || clusterName=$1

terraform init -input=false
terraform plan -input=false -var="clusterName=$clusterName" -out=tfplan.out
terraform apply tfplan.out
