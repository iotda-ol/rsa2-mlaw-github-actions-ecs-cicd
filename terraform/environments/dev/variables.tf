variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "cicd-demo-app"
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "cicd-demo-cluster"
}

variable "ecs_service_name" {
  description = "Name of the ECS service"
  type        = string
  default     = "cicd-demo-service"
}

variable "container_name" {
  description = "Name of the container"
  type        = string
  default     = "cicd-demo-app"
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 3000
}

variable "enable_github_oidc" {
  description = "Enable GitHub OIDC provider"
  type        = bool
  default     = false
}

variable "github_repo" {
  description = "GitHub repository (owner/repo)"
  type        = string
  default     = "iotda-ol/rsa2-mlaw-github-actions-ecs-cicd"
}
