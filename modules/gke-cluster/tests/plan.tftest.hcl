mock_provider "google" {}

variables {
  name       = "payments-dev"
  project_id = "platform-dev-000000"
  region     = "us-central1"
  network    = "platform-dev"
  subnetwork = "platform-dev-us-central1"
}

run "autopilot_by_default" {
  command = plan

  assert {
    condition     = google_container_cluster.this.enable_autopilot == true
    error_message = "default mode must be autopilot"
  }
  assert {
    condition     = length(google_container_node_pool.default) == 0
    error_message = "autopilot must not create a node pool"
  }
  assert {
    condition     = google_container_cluster.this.private_cluster_config[0].enable_private_nodes
    error_message = "nodes must be private"
  }
}

run "standard_size_m" {
  command = plan

  variables {
    mode = "standard"
    size = "M"
  }

  assert {
    condition     = google_container_node_pool.default[0].autoscaling[0].max_node_count == 6
    error_message = "size M must cap at 6 nodes"
  }
  assert {
    condition     = google_container_node_pool.default[0].node_config[0].workload_metadata_config[0].mode == "GKE_METADATA"
    error_message = "workload identity metadata must be on"
  }
  assert {
    condition     = google_container_cluster.this.workload_identity_config[0].workload_pool == "platform-dev-000000.svc.id.goog"
    error_message = "workload identity pool must be set"
  }
}

run "rejects_unknown_size" {
  command = plan
  variables {
    size = "XL"
  }
  expect_failures = [var.size]
}

run "labels_carry_platform_defaults" {
  command = plan
  variables {
    labels = { team = "payments" }
  }
  assert {
    condition     = google_container_cluster.this.resource_labels["managed-by"] == "opentofu" && google_container_cluster.this.resource_labels["team"] == "payments"
    error_message = "labels must merge platform defaults with caller labels"
  }
}
