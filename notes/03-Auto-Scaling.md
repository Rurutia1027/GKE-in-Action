# Auto-Scaling in GKE -- Quick Overview 
In Google Kubernetes Engine (GKE), autoscaling ensures your cluster dynamically adjusts compute resources based on workload demand. 

There are three key layers of autoscaling: 

### Cluster Autoscaler (CA)
- Automatically **adds** or **removes nodes** in a node pool
- Works based on pending pods (if pods can't be scheduled -> new nodes are created)
- When nodes are underutilized -> they get drained and removed

### Horizontal Pod Autoscaler (HPA)
- Adjusts the number of **pod replicas** based on CPU/memory or custom metrics

### Vertical Pod Autoscaler (VPA)
- Adjusts **resource requests** and **limits** of containers automatically.

Typically, Terraform configures **Cluster Autoscaler(node-level scaling).**
HPA and VPA are configured using Kubernetes mainfests later. 


## Terraform Example -- Enable Node Auto-Scaling 
You can extend your `main.tf` like this: 

```hcl
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
  required_version = ">= 1.7.0"
}

provider "google" {
  project     = "gcp-devops-474305"
  region      = "us-central1"
  credentials = file("~/Downloads/gcp-devops-xxx.json")
}

# ---  GKE Cluster --- 
resource "google_container_cluster" "primary" {
    name = "gke-deep-dive"
    location = "us-central1"

    remove_default_node_pool = true 
    deletion_protection = false 
}

# --- Node Pool with Autoscaling ---
resource "google_container_node_pool" "primary_nodes" {
    name = "primary-node-pool"
    location = google_container_cluster.primary.location
    cluster = google_container_cluster.primary.name

    node_count = 1

    node_config {
        machine_type = "e2-medium"
        disk_size_gb = 26
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
```

#### **Explanation**
- `remove_default_node_pool` = true -> disables the default pool created by GKE
- Then, you define your **own node pool (google_container_node_pool)** with:
> `autoscaling` block to set `min_node_count` and `max_node_count`.
> management block to enable self-healing and upgrades.
- GKE will automatically scale the number of nodes in that pool based on pod scheduling demand. 


## Difference Between Native Kubernetes Autoscaling and GKE Autoscaling 
Both Kubernetes(K8S) and Google Kubernetes Engine (GKE) support autoscaling, but GKE extends and manages it in a more integrated, managed way. 


- Native Kubernetes -> more controle, more setup effort.
- GKE -> managed, cloud-native experience with better integration into Google Cloud's monitoring and scaling ecosystem.
- GKE also offers **Autopilot Mode**, where Google fully manages nodes, scaling, and scheduling -- you only define workloads and quotas.  