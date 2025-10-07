terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
  required_version = ">= 1.7.0"
}

resource "google_container_cluster" "primary" {
  name     = "gke-deep-dive"
  location = "us-central1"
  initial_node_count = 1

  node_config {
    machine_type = "e2-medium"
    disk_size_gb = 20
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  remove_default_node_pool = false
  deletion_protection      = false
}