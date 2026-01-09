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
  #   key            = "dev/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "development"
      Project     = "cicd-demo"
      ManagedBy   = "Terraform"
    }
  }
}

# Local variables
locals {
  environment = "dev"
  common_tags = {
    Environment = "development"
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
  enable_blue_green  = false
  enable_github_oidc = var.enable_github_oidc
  github_repo        = var.github_repo

  tags = local.common_tags
}

# ECR Module
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
  task_cpu                     = "256"
  task_memory                  = "512"
  desired_count                = 1
  min_capacity                 = 1
  max_capacity                 = 3
  vpc_id                       = module.networking.vpc_id
  public_subnet_ids            = module.networking.public_subnet_ids
  private_subnet_ids           = module.networking.private_subnet_ids
  alb_security_group_id        = module.networking.alb_security_group_id
  ecs_tasks_security_group_id  = module.networking.ecs_tasks_security_group_id
  execution_role_arn           = module.iam.ecs_task_execution_role_arn
  task_role_arn                = module.iam.ecs_task_role_arn
  ecr_repository_url           = module.ecr.repository_url
  aws_region                   = var.aws_region
  log_retention_days           = 7
  enable_blue_green            = false

  environment_variables = [
    {
      name  = "NODE_ENV"
      value = "development"
    },
    {
      name  = "PORT"
      value = "3000"
    }
  ]

  tags = local.common_tags
}
