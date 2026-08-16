variable "aws_region" {
  description = "AWS region in which to create the platform."
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Environment name used in resource names and tags."
  type        = string
  default     = "production"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.environment))
    error_message = "environment must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
  default     = "astronomy-shop-production"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes minor version. Confirm availability in the selected region before apply."
  type        = string
  default     = "1.33"
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the deployment role, in owner/repository format."
  type        = string
}

variable "node_instance_types" {
  description = "Instance types used by the on-demand managed node group."
  type        = list(string)
  default     = ["m7i.large", "m6i.large"]
}

variable "alert_email" {
  description = "Optional email address for security findings. Subscription confirmation is required."
  type        = string
  default     = ""
}
