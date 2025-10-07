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
# This block belongs to the GKE Node Pool resource, and it enables GKE Cluster Autoscaler (CA) for that node pool.
# It defines the range of nodes the autoscaler can adjust within -- meaning: 
# min_node_count = 1 -> The node pool will never scale below 1 node. 
# max_node_count = 5 -> The node pool will never scaling above 5 nodes. 
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


## Why You Don't See Resource Triggers in Terraform (HCL)
This Terraforms' Block: 
```hcl 
autoscaling {
    min_node_count = 1
    max_node_count = 5
}
```

This only defines the **scaling boundaries**, not **what triggers scaling**.

That's because in **GKE**, the Cluster Autoscaler (CA) doesn't directly watch CPU/memory usage -- it reacts to **Kubernetes scheduling pressure**, i.e., **pending** or **unschedulable pods**.

> So what triggers GKE Cluster Autoscaler ? 

It's not CPU thresholds -- it's whether pods can be scheduled. 

Example Scenario:
- You deploy a new workload requesting 2 CPU, but all existing nodes are at 90% CPU.
- Kubernetes scheduler can't place the pod -> the pod goes into Pending state. 
- GKE's Cluster Autoscaler detects the pending pod. 
- It adds a new node to the node pool (up to `max_node_count`).
- Once the new node joins, the pod gets scheduled. 
- Later, if that node becomes empty for a while -> CA detects it (down to `min_node_count`)

So no need to define CPU/memory triggers in Terraform -- GKE automatically watches scheduling status and scales the cluster accordingly. 


### So, Who Watches CPU/Memory 
That's the job of the Horizontal Pod Autoscaler (HPA) -- not CA
For example: 
```bash 
kubectl autoscale deployment myapp --cpu-percent=70 --min=2 --max=10
```

- HPA scales pods of myapp when their average CPU > 70%
- If there aren't enough nodes to fit those new pods -> CA steps in to add nodes

Think it works in this way: 
```
User traffic ↑
  ↓
Pods get busy (CPU ↑)
  ↓
HPA adds pods (replicas ↑)
  ↓
Pods can’t fit → CA adds nodes
```


### So in Terraform 

You generally define **two layers**: 

#### Layer One: Cluster / Node Pool Autoscaling (handled by GKE)
```hcl 
autoscaling {
  min_node_count = 1
  max_node_count = 5
}
```

#### Layer Two: Workload Autoscaling (handled by Kubernetes / HPA)
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: myapp-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
```

### Summmary 
- Cluster Autoscaler (CA) it's Node-level, defined in Terraform/GKE, and triggered by pending Pods (scheduling pressure)
- Horizontal Pod Autoscaler (HPA), it's Pod-level, defined in Kubernentes YAML / Terraform (k8s provider), and triggered by CPU / Memory/ Custom metrics those factors. 