# GKE Cluster Networking: VPC-native vs Route-based
## Overview 
Google Kubernetes Engine (GKE) cluster can use **two main networking modes** for pods: 
- Route-based cluster
- VPC-native cluster (alias IP)

The choice affects how **Pods IPs are assigned**, **how networking works with the VPC**, and **scalability**.

## Route-based Clusters 
### How it works 
- Pods get IPs from a cluster-internal range (e.g., 10.0.0.0/14). 
- GKE creates routes in the VPC for each node, pointing to pod IPs.
- Traffic between pods uses **node routing**(node routes packets to the pod).


### Pros of Route-based Clusters 
- Simple setup, works out of the box
- **Older clusters** often use this by default

### Cons/Limitations 
- Scalability issues:
> Each node adds routes in the VPC -> large clusters -> many routes -> harder to manage.
- IP conflicts: Pod IP range is separate from VPC -> potential overlap 
- Limited flexibility for private GKE / hybrid networking 

### Use Cases 
- Small clusters (< 100 nodes)
- Legacy setups or labs where VPC-native is not needed 

## VPC-native Clusters (Alias IPs)
### How it works
- Use VPC-native networking (alias IPs)
- Pods get IPs directly from secondary IP ranges in a VPC subnet. 
- No per-node routes are created; GCP routes traffic via VPC routing.

### Architecture 
```bash 
[VPC Subnet]
  ├─ Primary range → Node IPs
  └─ Secondary range → Pod IPs (pods/services)
```

- Pod IPs are **first-class VPC IPs**
- Nodes don't need to route packets manually.


### Pros 
- Highly scalable: no per-node routes -> clusters can be hundreds/thousands of nodes.
- Pods can directly communicate with VPC resources
- Supports **private GKE clusters** and hybird networking 
- Easier IP management with secondary ranges

### Cons 
- Slightly more complex initial setup (need secondary ranges, subnets planning)
- May require planning for future growth for pods/services IPs

### Use Cases 
- Medium to large clusters (> 100 nodes)
- Private clusters / hybird VPC networking 
- Production environments requiring predicatable IP addressing 

## Quick Comparison Table 
### Pod IP assignment 
- Route-based: Cluster-internal CIDR, not in VPC; 
- VPC-native (Alias IP): Secondary range in VPC subnet. 


### Routing 
- Route-based: Per-node routes
- VPC-native: VPC routing (no per-node routes)

### Scalability
- Route-based: Limited by route table size, 
- VPC-native: High, thousands of nodes 


### Pod-VPC communication 
- Route-based: NAT required for VPC access 
- VPC-native: Direct, no NAT needed 

### Private cluster support
- Route-based: limited
- VPC-native: Full support

### Complexity
- Route-based: Simple 
- VPC-native: Requires subnet planning 

## Notes for Beginners
- **Route-based** = older method, simpler but doesn't scale well
- **VPC-native** = modern recommended method, scales better, integrates with private clusters
- Always plan your subnet secondary ranges in VPC-native clusters: one for pods, one for services. 
- VPC-native is **mandatory** if you want private clusters with no public endpoints. 

## Practical Tips 
- For lab or experiments, route-based is okay for < 50 nodes
- For real-world production, always use VPC-native 
- In Terraform/GCP, VPC-native clusters require
> network + subnetwork 
> ip_allocation_policy with **secondary ranges** for pods and services. 

--- 

# Terraform for Route-based and VPC-native GKE CLusters 

## Route-based GKE Cluster in Terraform  
```hcl 
provider "google" {
    project = "gcp-project-id"
    region  = "us-central1"
    zone    = "us-central1-a"
}

resource "google_container_cluster" "route_based_cluster" {
    name = "route-cluster"
    location = "us-central1"
    initial_node_count = 1
    networking_mode = "ROUTE_BASED" 

    node_config = {
        machine_type = "e2-medium"
        disk_size_gb = 50
        oauth_scopes = [
            "https://www.googleapis.com/auth/cloud-platform",
        ]
    }
}
```


## VPC-native GKE Cluster in Terraform 
```hcl 
provider "google" {
    project = "gcp-project-id"
    region = "us-central1"
    zone = "us-central1-a
}

# Create custom VPC 
resource "google_compute_network" "vpc_network" {
    name = "vpc-native-network"
    auto_create_subnetworks = false 
}

# Create subnet with secondary ranges for pods & services 
resource "google_compute_subnetwork" "vpc_subnet" {
    name = "vpc-native-subnet"
    ip_cidr_range = "10.0.0.0/16"
    network = google_compute_network.vpc_network.id
    region = "us-central1"
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

# Create VPC-native GKE cluster 
resource "google_container_cluster" "vpc_native_cluster" {
    name = "vpc-native-cluster"
    location = "us-central1"
    remove_default_node_pool = true 
    initial_node_count = 1
    networking_mode = "VPC_NATIVE"
    network = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.vpc_subnet.id 

    ip_allocation_policy {
        cluster_secondary_range_name = "pods"
        service_secondary_range_name = "services"
    }

    node_config {
        machine_type = "e2-medium"
        disk_size_gb = 50 
        oauth_scopes = [
            "https://www.googleapis.com/auth/cloud-platform",
        ]
    }

}
```

#### Notes
- `networking_mode="VPC_NATIVE"` -> modern alias IP cluster
- Pods/services IPs come from **secondary ranges** in subnet
- Supports private clusters and hybrid networking 
- Scales much better for large clusters 