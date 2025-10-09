# Create a subnet inside the default VPC 
resource "google_compute_subnetwork" "gke_deep_dive_subnet" {
    name = "gke-deep-dive-subnet"
    ip_cidr_range = "10.10.0.0/24"
    region = var.region 
    network = "default"
}

# Create a VPC-native (IP alias) GKE cluster
resource "google_container_cluster" "gke_deep_dive_vpc_native" {
    name = "gke-deep-dive-vpc-native"
    location = var.region 
    remove_default_node_pool = true 
    initial_node_count = 1 

    # Enable VPC-native (IP alias) mode 
    networking_mode = "VPC_NATIVE"

    ip_allocation_policy {}

    subnetwork = google_compute_subnetwork.gke_deep_dive_subnet.self_link 

    addons_config {
        http_load_balancing {
            disabled = false 
        }
    }
}

# Add a node pool to the cluster
resource "google_container_node_pool" "primary_nodes" {
    name       = "gke-deep-dive-node-pool"
    cluster    = google_container_cluster.gke_deep_dive_vpc_native.name
    location   = var.region

    node_config {
        machine_type = "e2-medium"
        disk_type    = "pd-standard"
        disk_size_gb = 10
        oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
    }

    initial_node_count = 1
}