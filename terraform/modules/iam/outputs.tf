output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_task_execution_role_name" {
  description = "Name of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution_role.name
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task_role.arn
}

output "ecs_task_role_name" {
  description = "Name of the ECS task role"
  value       = aws_iam_role.ecs_task_role.name
}

output "codedeploy_role_arn" {
  description = "ARN of the CodeDeploy role"
  value       = var.enable_blue_green ? aws_iam_role.codedeploy_role[0].arn : ""
}

output "codedeploy_role_name" {
  description = "Name of the CodeDeploy role"
  value       = var.enable_blue_green ? aws_iam_role.codedeploy_role[0].name : ""
}

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions role"
  value       = var.enable_github_oidc ? aws_iam_role.github_actions_role[0].arn : ""
}

output "github_actions_role_name" {
  description = "Name of the GitHub Actions role"
  value       = var.enable_github_oidc ? aws_iam_role.github_actions_role[0].name : ""
}
