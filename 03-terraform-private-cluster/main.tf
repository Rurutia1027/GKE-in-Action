############################################################
# 1. Create VPC Network
# This network will host the private GKE cluster and the Bastion host
############################################################
resource "google_compute_network" "vpc_network" {
    name = "private-gke-network"
    auto_create_subnetworks = false # Disable auto subnet, plan IPs manually 
}

############################################################
# 2. Create Subnet
# The subnet includes:
# - main CIDR block for nodes
# - secondary ranges for pods and services
############################################################
resource "google_compute_subnetwork" "private_subnet" {
    name = "private-subnet" 
    ip_cidr_range = "10.0.0.0/16" # Main node IP range 
    network = google_compute_network.vpc_network.id 
    region = "us-central1"
    private_ip_google_access = true # Nodes can reach Google APIs without public IP 

    # Pod IP range 
    secondary_ip_range {
        range_name = "pods"
        ip_cidr_range = "10.1.0.0/16"
    }

    # Service IP range 
    secondary_ip_range {
        range_name = "services"
        ip_cidr_range = "10.2.0.0/20"
    }
}


############################################################
# 3. Bastion Host (Jump Host)
# Provides a secure entry point to access the private GKE cluster
############################################################
resource "google_compute_instance" "bastion" {
    name = "bastion-host"
    machine_type = "e2-medium" 
    zone = "us-central1-a"

    boot_disk {
        initialize_params {
            image = "debian-cloud/debian-12" # debian OS 
            size = 20
        }
    }

    network_interface {
        network = google_compute_network.vpc_network.id 
        subnetwork = google_compute_subnetwork.private_subnet.id 
        access_config {} # assign a public IP for SSH access 
    }

    metadata = {
        # SSH key to login Bastion host
        ssh-keys = "rurutia1027:${file("/Users/emma/.ssh/id_rsa.pub")}"
    }

    tags = ["bastion"]
}

############################################################
# 4. Optional: Firewall rule to allow SSH only from your IP
############################################################
resource "google_compute_firewall" "bastion-ssh" {
    name = "allow-ssh-bastion"
    network = google_compute_network.vpc_network.id 

    allow {
        protocol = "tcp"
        ports = ["22"]
    }

    source_ranges = ["${local_ip_address}/32"]
    target_tags = ["bastion"]
}


############################################################
# 5. Create Private GKE Cluster
# - enable_private_nodes: nodes have no public IP
# - enable_private_endpoint: master endpoint only accessible inside VPC
############################################################
resource "google_container_cluster" "private_cluster" {
    name = "private-gke-cluster"
    location = "us-central1"
    remove_default_node_pool = true # Use a custom node pool 
    initial_node_count = 1
    networking_mode = "VPC_NATIVE"
    network            = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.private_subnet.id

    private_cluster_config {
        enable_private_nodes = true # Nodes do not have public IP 
        enable_private_endpoint = true # Master endpoint private only 
    }

    master_authorized_networks_config {
        cidr_blocks {
            cidr_block   = "10.0.0.0/16"  # Allow all networks (or restrict to your bastion/VPN CIDR)
            display_name = "Private Network"
        }
  }

    ip_allocation_policy {
        cluster_secondary_range_name = "pods" # Pods secondary range 
        services_secondary_range_name = "services" # Services secondary range 
    }
}


############################################################
# 6. Custom Node Pool
# Configure node type and count
############################################################
resource "google_container_node_pool" "primary_nodes" {
    name = "primary-node-pool"
    cluster = google_container_cluster.private_cluster.name 
    location = google_container_cluster.private_cluster.location 
    node_count = 1

    node_config {
        machine_type = "e2-medium"
        disk_type    = "PD_STANDARD"   # cheaper HDD style
        disk_size_gb = 20               # smaller disk
        oauth_scopes = [
            "https://www.googleapis.com/auth/cloud-platform",
        ]
    }
}
