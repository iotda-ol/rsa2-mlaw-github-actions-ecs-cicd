terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment and configure for remote state
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "prod/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "production"
      Project     = "cicd-demo"
      ManagedBy   = "Terraform"
    }
  }
}

# Local variables
locals {
  environment = "prod"
  common_tags = {
    Environment = "production"
    Project     = "cicd-demo"
    ManagedBy   = "Terraform"
  }
}

# Networking Module
module "networking" {
  source = "../../modules/networking"

  environment          = local.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  enable_nat_gateway   = true

  tags = local.common_tags
}

# IAM Module
module "iam" {
  source = "../../modules/iam"

  environment        = local.environment
  enable_blue_green  = true
  enable_github_oidc = var.enable_github_oidc
  github_repo        = var.github_repo

  tags = local.common_tags
}

# ECR Module (Shared with dev, but included for completeness)
module "ecr" {
  source = "../../modules/ecr"

  repository_name = var.ecr_repository_name

  tags = local.common_tags
}

# ECS Module
module "ecs" {
  source = "../../modules/ecs"

  environment                  = local.environment
  cluster_name                 = var.ecs_cluster_name
  service_name                 = var.ecs_service_name
  container_name               = var.container_name
  container_port               = var.container_port
  task_cpu                     = "512"
  task_memory                  = "1024"
  desired_count                = 2
  min_capacity                 = 2
  max_capacity                 = 10
  vpc_id                       = module.networking.vpc_id
  public_subnet_ids            = module.networking.public_subnet_ids
  private_subnet_ids           = module.networking.private_subnet_ids
  alb_security_group_id        = module.networking.alb_security_group_id
  ecs_tasks_security_group_id  = module.networking.ecs_tasks_security_group_id
  execution_role_arn           = module.iam.ecs_task_execution_role_arn
  task_role_arn                = module.iam.ecs_task_role_arn
  ecr_repository_url           = module.ecr.repository_url
  aws_region                   = var.aws_region
  log_retention_days           = 30
  enable_blue_green            = true
  codedeploy_role_arn          = module.iam.codedeploy_role_arn

  environment_variables = [
    {
      name  = "NODE_ENV"
      value = "production"
    },
    {
      name  = "PORT"
      value = "3000"
    }
  ]

  tags = local.common_tags
}

# Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.ecr.repository_url
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.ecs.alb_dns_name
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.ecs.service_name
}

output "github_actions_role_arn" {
  description = "GitHub Actions IAM role ARN"
  value       = module.iam.github_actions_role_arn
}

output "blue_target_group_name" {
  description = "Blue target group name"
  value       = module.ecs.blue_target_group_name
}

output "green_target_group_name" {
  description = "Green target group name"
  value       = module.ecs.green_target_group_name
}
