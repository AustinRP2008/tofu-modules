output "name" {
  description = "Cluster name."
  value       = google_container_cluster.this.name
}

output "location" {
  description = "Cluster region."
  value       = google_container_cluster.this.location
}

output "endpoint" {
  description = "Control plane endpoint."
  value       = google_container_cluster.this.endpoint
  sensitive   = true
}

output "node_pool" {
  description = "Effective node pool sizing (null for autopilot)."
  value       = local.standard ? { machine_type = local.size.machine_type, min = local.size.min, max = local.size.max } : null
}
