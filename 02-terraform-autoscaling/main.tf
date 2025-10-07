terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
  required_version = ">= 1.7.0"
}

# terraform plan 
# terraform apply 

# verify whether terraform config refresh to GKE instance: 
# gcloud container clusters describe gke-deep-dive --region us-central1 \
#  --format="value(autoscaling)"
# gcloud container node-pools describe primary-nodes \
#  --cluster=gke-deep-dive --region=us-central1

resource "google_container_cluster" "primary" {
  name     = "gke-deep-dive"
  location = "us-central1"

  initial_node_count = 1
  remove_default_node_pool = true
  deletion_protection      = false
}

# Custom Node Pool with autoscaling 
resource "google_container_node_pool" "primary_nodes" {
  name = "primary-node-pool"
  cluster = google_container_cluster.primary.name 
  location = google_container_cluster.primary.location 

  node_config {
    machine_type = "e2-medium"
    disk_size_gb = 20
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  autoscaling {
    min_node_count = 1
    max_node_count = 5
  }

  management {
    auto_repair = true 
    auto_upgrade = true 
  }
}