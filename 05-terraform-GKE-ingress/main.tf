############################################################
# Simple Route-Based GKE Cluster
# Legacy networking (ROUTES) - no secondary ranges required
############################################################
resource "google_container_cluster" "route_based_gke_cluster" {
  name               = "route-based-cluster"
  location           = var.region
  networking_mode    = "ROUTES"         # Legacy route-based networking
  initial_node_count = 1
  deletion_protection = false

  node_config {
    machine_type = "e2-medium"
    disk_type    = "pd-standard"
    disk_size_gb = 20
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}