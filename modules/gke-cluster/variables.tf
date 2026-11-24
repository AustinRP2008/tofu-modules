variable "name" {
  description = "Cluster name."
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,38}[a-z0-9]$", var.name))
    error_message = "name must be 4-40 chars of lowercase letters, digits and hyphens."
  }
}

variable "project_id" {
  description = "GCP project that owns the cluster (platform-provided per environment)."
  type        = string
}

variable "region" {
  description = "GCP region; clusters are always regional."
  type        = string
}

variable "network" {
  description = "VPC network self link or name (platform-provided per environment)."
  type        = string
}

variable "subnetwork" {
  description = "Subnetwork with secondary ranges for pods and services (platform-provided)."
  type        = string
}

variable "mode" {
  description = "autopilot (Google manages nodes) or standard (platform-managed node pool)."
  type        = string
  default     = "autopilot"
  validation {
    condition     = contains(["autopilot", "standard"], var.mode)
    error_message = "mode must be autopilot or standard."
  }
}

variable "size" {
  description = "T-shirt size; maps to machine type and autoscaling bounds for standard mode."
  type        = string
  default     = "S"
  validation {
    condition     = contains(["S", "M", "L"], var.size)
    error_message = "size must be S, M or L."
  }
}

variable "release_channel" {
  description = "GKE release channel."
  type        = string
  default     = "REGULAR"
  validation {
    condition     = contains(["RAPID", "REGULAR", "STABLE"], var.release_channel)
    error_message = "release_channel must be RAPID, REGULAR or STABLE."
  }
}

variable "deletion_protection" {
  description = "Block destroy. The platform sets this true for prod."
  type        = bool
  default     = true
}

variable "labels" {
  description = "Extra resource labels (team, cost-center, env, ttl ...)."
  type        = map(string)
  default     = {}
}
