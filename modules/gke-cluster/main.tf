locals {
  sizes = {
    S = { machine_type = "e2-standard-2", min = 1, max = 3 }
    M = { machine_type = "e2-standard-4", min = 2, max = 6 }
    L = { machine_type = "e2-standard-8", min = 3, max = 12 }
  }
  size     = local.sizes[var.size]
  standard = var.mode == "standard"
  labels   = merge(var.labels, { managed-by = "opentofu", module = "gke-cluster" })
}

resource "google_container_cluster" "this" {
  name                = var.name
  project             = var.project_id
  location            = var.region
  network             = var.network
  subnetwork          = var.subnetwork
  deletion_protection = var.deletion_protection
  resource_labels     = local.labels

  enable_autopilot = local.standard ? null : true

  # Standard mode: start with no default pool (GKE 1.36.4+) and manage our own below.
  initial_node_count = local.standard ? 0 : null
  datapath_provider  = local.standard ? "ADVANCED_DATAPATH" : null

  release_channel {
    channel = var.release_channel
  }

  ip_allocation_policy {}

  # Hidden, opinionated defaults: nodes never get public IPs.
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
  }

  dynamic "workload_identity_config" {
    for_each = local.standard ? [1] : []
    content {
      workload_pool = "${var.project_id}.svc.id.goog"
    }
  }
}

resource "google_container_node_pool" "default" {
  count = local.standard ? 1 : 0

  name     = "default"
  project  = var.project_id
  location = var.region
  cluster  = google_container_cluster.this.name

  autoscaling {
    min_node_count = local.size.min
    max_node_count = local.size.max
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type = local.size.machine_type
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
    labels       = local.labels

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
}
