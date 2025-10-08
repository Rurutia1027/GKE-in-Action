# GKE Private Cluster 
## What is a Private GKE Cluster?
- A GKE cluster where nodes do not have public IPs
- Control plan (master) has a private endpoint, accessible only from authorized networks
- Traffic from nodes to the internet goes through Cloud NAT if needed  

## Key Components 
**Master Endpoint**: private, can enable public endpoint with authorized networks for hybrid access
**Node VMs**: private, No public IPs; communicate via VPC
**Pod IPs**: private, Internal VPC IPs only
**Service**: ClusterIP / LoadBalancer, Private LB for internal access; external LB needs NAT or proxy 


## Networking Basics 
- **VPC-native(alias IP)** is required
- Subnets must have enough seconary ranges: 
> One for pods 
> One for services 
- Cloud NAT needed if nodes need outbound internet access (updates, container registry). 

## Security Advantages 
- Reduced attach surface (nodes not exposed publicly)
- Communication is internal (private IPs)
- Optional private endpoint for master reduces exposure to public internet

## Accessing the Cluster 
- `kubectl` requires connectivity to private master endpoint
- Options: 
> VPN/Cloud Interconnect
> Bastion host inside VPC 
> Authorized networks (if public endpoint enabled)

## Limitations 
- Some addons or third-party integrations may require public access.
- Requires proper VPC planning
- Initial setup slightly more complex than public cluster

--- 

# Creating a Private GKE Cluster via Terraform 
Below is a **basic example** using Terraform: 

```hcl 
provider "google" {
    project = "gcp-project-id"
    region = "us-central1"
}

resource "google_compute_network" "vpc_network" {
    name = "private-gke-network"
    auto_create_subnetworks = false 
}

resource "google_compuet_subnetwork" "private_subnet" {
    name = "private-subnet"
    ip_cidr_range = "10.0.0.0/16"
    network = google_compute_network.vpc_network.id
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

resource "google_container_cluster" "private_cluster" {
    name = "private-gke-cluster"
    location = "us-central1"
    initial_node_count = 1
    remove_default_node_pool = true
    networking_mode = "VPC_NATIVE"

    private_cluster_config {
        enable_private_nodes = true
        enable_private_endpoint = false 
        master_ipv4_cidr_block = "172.16.0.0/28"
    }

    ip_allocation_policy {
        cluster_secondary_range_name = "pods"
        services_secondary_range_name = "services"
    }
}

resource "google_container_node_pool" "primary_nodes" {
    name = "primary-node-pool"
    cluster = google_container_cluster.private_cluster.name
    location = google_container_cluster.private_cluster.location 
    node_count = 1

    node_config {
        machine_type = "e2-medium"
        oauth_scopes = [
            "https://www.googleapis.com/auth/cloud-platform",
        ]
    }
}
```

### Terraform Notes 
- **enable_private_nodes=true** this means nodes of the cluster have no public IP
- **enable_private_endpoint=false** this means master is only accessile privately
- **Seconary IP ranges** this means IP ranges should be categoried into pods and services 
- **Cloud NAT** add if you need outbound internet for nodes
- **remove_deafult_node_pool=true** this means optional but recommended to control node pool configs 


### Summary 
- Private clusters = nodes without public IP + private master 
- Requires VPC planning (subnets, seconary ranges)
- Security is higher, but you need VPN/bastion for `kubectl` access
- Terraform can fully automate the setup with `private_cluster_config`. 


### Note: Multiple Ways to Access a Private GKE Cluster 
#### Private nodes + private master(control plane that kubectl connect to) with Bastion host 
- Nodes and master have no public IP
- Access via Bastion or VPN/Cloud Interconnect.
- Most secure approach for production 

#### Private nodes + public master endpoint (authorized networks)
- Nodes private, master endpoint publicly reachable but restricted to specific IPs
- Easier for remote access from your labtop or CI/CD
- Slightly less secure than fully private. 