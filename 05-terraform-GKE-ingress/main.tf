############################################################
# 1. Network setup (VPC-native for Ingress)
############################################################
resource "google_compute_network" "vpc_network" {
    name = "gke-ingress-network"
    auto_create_subnetworks = false 
}

resource "google_compute_subnetwork" "subnet" {
    name = "gke-subnet"
    region = var.region 
    network = google_compute_network.vpc_network.id 
    ip_cidr_range = "10.0.0.0/16"
    private_ip_google_access = true 

    secondary_ip_range {
        range_name = "pods"
        ip_cidr_range = "10.1.0.0/16"
    }

    secondary_ip_range {
        range_name = "services"
        ip_cidr_range = "10.2.0.0/20"
    }
}


############################################################
# 2. Create GKE Cluster (VPC-native)
############################################################
resource "google_container_cluster" "gke_cluster" {
    name = "gke-ingress-demo"
    location = var.region 
    networking_mode = "VPC_NATIVE" 
    network = google_compute_network.vpc_network.id 
    subnetwork = google_compute_subnetwork.subnet.id 
    remove_default_node_pool = true 
    deletion_protection = false 

    ip_allocation_policy {
        cluster_secondary_range_name = "pods"
        service_secondary_range_name = "services"        
    }

    private_cluster_config {
        enable_private_nodes = false # public cluster for demo 
        enable_private_endpoint = false 
    }

    initial_node_count = 1
}

############################################################
# 3. Node Pool
############################################################
resource "google_container_node_pool" "primary_pool" {
    name = "primary-pool"
    cluster = google_container_cluster.gke_cluster.name 
    location = google_container_cluster.gke_cluster.location 
    node_count = 2 

    node_config {
        machine_type = "e2-medium"
        disk_size_gb = 20
        oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
    }
}