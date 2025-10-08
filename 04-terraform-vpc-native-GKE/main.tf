############################################################
# 1. Create custom VPC network
############################################################
resource "google_compute_network" "vpc_network" {
  name                    = "vpc-native-network"
  auto_create_subnetworks = false
}

############################################################
# 2. Create subnet with secondary ranges for Pods & Services
############################################################
resource "google_compute_subnetwork" "vpc_subnet" {
  name                     = "vpc-native-subnet"
  ip_cidr_range            = "10.0.0.0/16"    # Primary range for node IPs
  region                   = "us-central1"
  network                  = google_compute_network.vpc_network.id
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.1.0.0/16"   # Pod IPs
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.2.0.0/20"   # ClusterIP services
  }
}

############################################################
# 3. Create VPC-native GKE cluster
############################################################
resource "google_container_cluster" "vpc_native_cluster" {
  name                     = "vpc-native-cluster"
  location                 = "us-central1"
  networking_mode          = "VPC_NATIVE"
  network                  = google_compute_network.vpc_network.id
  subnetwork               = google_compute_subnetwork.vpc_subnet.id
  remove_default_node_pool = true
  initial_node_count       = 0

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  node_config {
    machine_type = "e2-medium"
    disk_type    = "pd-standard"
    disk_size_gb = 20
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

############################################################
# 4. Create node pool for the cluster
############################################################
resource "google_container_node_pool" "primary_nodes" {
  name       = "primary-node-pool"
  location   = google_container_cluster.vpc_native_cluster.location
  cluster    = google_container_cluster.vpc_native_cluster.name
  node_count = 1

  node_config {
    machine_type = "e2-medium"
    disk_type    = "PD_STANDARD"
    disk_size_gb = 20
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

############################################################
# 5. Notes
# - VPC-native uses subnet secondary ranges for Pods & Services
# - No per-node routes needed (VPC routing handles Pod IPs)
# - Scales better and supports private clusters
############################################################