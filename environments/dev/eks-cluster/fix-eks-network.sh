#!/bin/bash
# fix-routes.sh

REGION="ap-southeast-2"

echo "Finding Dev VPC private route tables..."

# Get Dev VPC ID
DEV_VPC_ID=$(aws ec2 describe-vpcs \
  --region $REGION \
  --filters "Name=tag:Name,Values=dev-workload-vpc" \
  --query 'Vpcs[0].VpcId' \
  --output text)

echo "Dev VPC: $DEV_VPC_ID"

# Get peering connection
PCX_ID=$(aws ec2 describe-vpc-peering-connections \
  --region $REGION \
  --filters "Name=status-code,Values=active" \
  --query "VpcPeeringConnections[?RequesterVpcInfo.VpcId=='$DEV_VPC_ID' || AccepterVpcInfo.VpcId=='$DEV_VPC_ID'].VpcPeeringConnectionId" \
  --output text | awk '{print $1}')

echo "Peering: $PCX_ID"
echo ""

# Find private route tables
aws ec2 describe-route-tables \
  --region $REGION \
  --filters "Name=vpc-id,Values=$DEV_VPC_ID" "Name=tag:Name,Values=*private*" \
  --query 'RouteTables[*].RouteTableId' \
  --output text | tr '\t' '\n' | while read RTB_ID; do
  
  echo "Processing route table: $RTB_ID"
  
  # Delete any IGW route
  aws ec2 delete-route \
    --route-table-id $RTB_ID \
    --destination-cidr-block 0.0.0.0/0 \
    --region $REGION 2>/dev/null && echo "  Removed IGW route" || echo "  No IGW route found"
  
  # Add peering route
  aws ec2 create-route \
    --route-table-id $RTB_ID \
    --destination-cidr-block 0.0.0.0/0 \
    --vpc-peering-connection-id $PCX_ID \
    --region $REGION 2>/dev/null && echo "  ✅ Added peering route" || echo "  ✅ Peering route exists"
  
  echo ""
done

echo "Done! Routes fixed."
