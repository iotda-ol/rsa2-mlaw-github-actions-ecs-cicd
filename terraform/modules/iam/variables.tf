variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "enable_blue_green" {
  description = "Enable blue/green deployment with CodeDeploy"
  type        = bool
  default     = false
}

variable "enable_github_oidc" {
  description = "Enable GitHub OIDC provider for secure authentication"
  type        = bool
  default     = false
}

variable "github_repo" {
  description = "GitHub repository in format 'owner/repo'"
  type        = string
  default     = ""
}
