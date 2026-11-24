output "name" {
  description = "Cluster name."
  value       = aws_eks_cluster.this.name
}

output "endpoint" {
  description = "Control plane endpoint (private)."
  value       = aws_eks_cluster.this.endpoint
  sensitive   = true
}

output "node_group" {
  description = "Effective node group sizing (null for Auto Mode)."
  value       = local.auto ? null : { instance_type = local.size.instance_type, min = local.size.min, max = local.size.max }
}
