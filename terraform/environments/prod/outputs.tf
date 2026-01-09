# Production Environment Outputs

output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.networking.vpc_cidr
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.networking.private_subnet_ids
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.ecr.repository_url
}

output "ecr_repository_name" {
  description = "ECR repository name"
  value       = module.ecr.repository_name
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.ecs.alb_dns_name
}

output "alb_arn" {
  description = "ALB ARN"
  value       = module.ecs.alb_arn
}

output "alb_zone_id" {
  description = "ALB Zone ID (for Route53 alias records)"
  value       = module.ecs.alb_zone_id
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "ecs_cluster_arn" {
  description = "ECS cluster ARN"
  value       = module.ecs.cluster_arn
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.ecs.service_name
}

output "task_definition_family" {
  description = "Task definition family"
  value       = module.ecs.task_definition_family
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name"
  value       = module.ecs.cloudwatch_log_group_name
}

output "blue_target_group_name" {
  description = "Blue target group name"
  value       = module.ecs.blue_target_group_name
}

output "blue_target_group_arn" {
  description = "Blue target group ARN"
  value       = module.ecs.blue_target_group_arn
}

output "green_target_group_name" {
  description = "Green target group name"
  value       = module.ecs.green_target_group_name
}

output "green_target_group_arn" {
  description = "Green target group ARN"
  value       = module.ecs.green_target_group_arn
}

output "codedeploy_app_name" {
  description = "CodeDeploy application name"
  value       = module.ecs.codedeploy_app_name
}

output "codedeploy_deployment_group_name" {
  description = "CodeDeploy deployment group name"
  value       = module.ecs.codedeploy_deployment_group_name
}

output "github_actions_role_arn" {
  description = "GitHub Actions IAM role ARN"
  value       = module.iam.github_actions_role_arn
}

output "ecs_task_execution_role_arn" {
  description = "ECS task execution role ARN"
  value       = module.iam.ecs_task_execution_role_arn
}

output "ecs_task_role_arn" {
  description = "ECS task role ARN"
  value       = module.iam.ecs_task_role_arn
}

output "codedeploy_role_arn" {
  description = "CodeDeploy role ARN"
  value       = module.iam.codedeploy_role_arn
}
