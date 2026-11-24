variable "name" {
  description = "Cluster name."
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,38}[a-z0-9]$", var.name))
    error_message = "name must be 4-40 chars of lowercase letters, digits and hyphens."
  }
}

variable "kubernetes_version" {
  description = "EKS Kubernetes minor version."
  type        = string
  default     = "1.34"
  validation {
    condition     = can(regex("^1\\.(3[2-9])$", var.kubernetes_version))
    error_message = "kubernetes_version must be a supported 1.3x minor (1.32+)."
  }
}

variable "compute_mode" {
  description = "auto (EKS Auto Mode manages nodes, storage and load balancing) or managed (platform node group)."
  type        = string
  default     = "auto"
  validation {
    condition     = contains(["auto", "managed"], var.compute_mode)
    error_message = "compute_mode must be auto or managed."
  }
}

variable "size" {
  description = "T-shirt size; maps to instance type and scaling bounds for managed mode."
  type        = string
  default     = "S"
  validation {
    condition     = contains(["S", "M", "L"], var.size)
    error_message = "size must be S, M or L."
  }
}

variable "subnet_ids" {
  description = "Private subnets for the control plane ENIs and nodes (platform-provided per environment)."
  type        = list(string)
  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "EKS needs subnets in at least two availability zones."
  }
}

variable "tags" {
  description = "Extra tags (team, cost-center, env, ttl ...)."
  type        = map(string)
  default     = {}
}
