#!/bin/bash

# === CONFIGURATION VARIABLES ===
CLUSTER_NAME="sales-dashboard-cluster"
REGION="us-east-1"
NODEGROUP_NAME="sales-dashboard-nodes"
NODE_TYPE="t3.medium"
DESIRED_CAPACITY=2
MIN_SIZE=1
MAX_SIZE=3
VPC_STACK_NAME="eks-vpc-stack"
K8S_VERSION="1.29"

# === STEP 1: CREATE VPC USING CLOUDFORMATION ===
echo "Creating VPC stack..."
aws cloudformation create-stack \
  --region $REGION \
  --stack-name $VPC_STACK_NAME \
  --template-url https://amazon-eks.s3.us-west-2.amazonaws.com/cloudformation/2020-06-10/amazon-eks-vpc-private-subnets.yaml \
  --capabilities CAPABILITY_NAMED_IAM

echo "Waiting for VPC stack to complete..."
aws cloudformation wait stack-create-complete \
  --region $REGION \
  --stack-name $VPC_STACK_NAME

# === STEP 2: EXTRACT VPC RESOURCES ===
VPC_ID=$(aws cloudformation describe-stacks --region $REGION --stack-name $VPC_STACK_NAME \
  --query "Stacks[0].Outputs[?OutputKey=='VpcId'].OutputValue" --output text)

SUBNET_IDS=$(aws cloudformation describe-stacks --region $REGION --stack-name $VPC_STACK_NAME \
  --query "Stacks[0].Outputs[?OutputKey=='SubnetIds'].OutputValue" --output text)

SECURITY_GROUP=$(aws cloudformation describe-stacks --region $REGION --stack-name $VPC_STACK_NAME \
  --query "Stacks[0].Outputs[?OutputKey=='SecurityGroups'].OutputValue" --output text)

# === STEP 3: CREATE EKS CLUSTER ===
echo "Creating EKS cluster..."
aws eks create-cluster \
  --region $REGION \
  --name $CLUSTER_NAME \
  --kubernetes-version $K8S_VERSION \
  --role-arn arn:aws:iam::<your-account-id>:role/EKSClusterRole \
  --resources-vpc-config subnetIds=${SUBNET_IDS},securityGroupIds=${SECURITY_GROUP}

echo "Waiting for cluster to become ACTIVE..."
aws eks wait cluster-active --name $CLUSTER_NAME --region $REGION

# === STEP 4: CREATE NODE GROUP ===
echo "Creating node group..."
aws eks create-nodegroup \
  --cluster-name $CLUSTER_NAME \
  --region $REGION \
  --nodegroup-name $NODEGROUP_NAME \
  --node-role arn:aws:iam::<your-account-id>:role/EKSNodeRole \
  --subnets ${SUBNET_IDS} \
  --scaling-config minSize=${MIN_SIZE},maxSize=${MAX_SIZE},desiredSize=${DESIRED_CAPACITY} \
  --instance-types ${NODE_TYPE} \
  --ami-type AL2_x86_64

echo "Waiting for node group to become ACTIVE..."
aws eks wait nodegroup-active --cluster-name $CLUSTER_NAME --nodegroup-name $NODEGROUP_NAME --region $REGION

# === STEP 5: UPDATE KUBECONFIG ===
echo "Updating kubeconfig..."
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

echo "✅ EKS setup complete. You can now deploy via kubectl or Jenkins!"
