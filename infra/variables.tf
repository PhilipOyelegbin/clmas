variable "environment_id" {
  description = "Unique identifier for the environment (e.g., dev-john-featurex)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.environment_id))
    error_message = "Environment ID must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "172.20.0.0/16"
}

variable "monitor_instance_type" {
  description = "Instance type for monitor tier"
  type        = string
  default     = "t3.micro"
}

variable "app_instance_type" {
  description = "Instance type for app tier"
  type        = string
  default     = "t3.micro"
}

variable "db_instance_type" {
  description = "Instance type for database"
  type        = string
  default     = "t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage for database in GB"
  type        = number
  default     = 20
}

variable "enable_nat_gateway" {
  description = "Whether to enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}