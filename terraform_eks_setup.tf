# main.tf - Terraform config to create EKS cluster with IAM roles

provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.2"

  name = "eks-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    "Name" = "eks-vpc"
  }
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.8.3"
  cluster_name    = "sales-dashboard-cluster"
  cluster_version = "1.29"

  subnet_ids         = module.vpc.private_subnets
  vpc_id             = module.vpc.vpc_id
  enable_irsa        = true

  eks_managed_node_groups = {
    default = {
      desired_size = 2
      max_size     = 3
      min_size     = 1

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
    }
  }

  tags = {
    "Environment" = "dev"
    "Project"     = "sales-dashboard"
  }
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "kubeconfig" {
  value = module.eks.kubeconfig_filename
}

output "node_group_role_arn" {
  value = module.eks.eks_managed_node_groups.default.iam_role_arn
}
