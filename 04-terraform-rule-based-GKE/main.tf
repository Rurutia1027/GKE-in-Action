############################################################
# 1. Create a simple GKE cluster using route-based networking
############################################################
resource "google_container_cluster" "route_based_gke_cluster" {
    name = "route-based-cluster"
    location = "us-central1" 
    networking_mode = "ROUTES" # <-- Legacy route-based networking 
    initial_node_count = 1

    node_config {
        machine_type = "e2-medium"
        disk_type = "pd-standard"
        disk_size_gb = 20
        oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
    }
}

############################################################
# 2. Notes
# - GKE automatically assigns Pod CIDRs internally (not in VPC)
# - Each node adds routes to the VPC for its pods
# - No secondary ranges required
# - Best for small test clusters (<100 nodes)
############################################################