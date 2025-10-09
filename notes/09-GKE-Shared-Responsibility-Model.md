# GKE Shared Responsibility Model 

Google Kubernetes Engine (GKE) operates on a **shared responsibility model**, meaning that **Google Cloud** and you the (consumer) each handle different aspects of security, infrastructure, and application management. 

## What Google Manages 
Google Cloud takes care of the **underlying infrastructure** and operational tasks, including: 

### Compute & Networking 
Virtual machines, networking, firewalls, and VPCs. 

### Control Plane 
Kubernetes API server, etcd database, cluster management, and upgrades for GKE-manaed control planes. 

### Master Security & Patching 
Securtiy patches for the control plane, cluster masters, and system components.


### High Availability 
Multi-zone or regional control plan replication, automatic failover.

### Integration with GCP Services
Built-in load balancing, logging, monitoring, and IAM integraiton


## What You (the Customer) Manage
You are responsible for the **applications**, and **configuration** running on the cluster: 

### Workloads & Pods
Containers, Deployments, StatefulSets, Jobs

### Node Pools 
Configuration, OS patching (if using self-managed nodes), scaling 

### Network Policies 
Service-to-service communication rules, firewall rules for applications

### RBAC & Access Control 
Permissions for users an service accounts inside Kubernentes 

### Secrets & Sensitive Data 
Storage and management of passwords, API keys, certificates 

### Container Image Security 
Ensuring images are from trusted sources and free of vulnerabilities.

### Summary 
You manage everything running on the nodes and how workloads interact. 



## How the Shared Model Helps
- **Security**: Google secures the infrastrucure; you focus on securing your apps. 
- **Reliability**: Google ensures control plane availability; you design fault-tolerance workloads.
- **Cost & Control**: You control workloads and node configuraiton, while Google manages operational overhead. 


## Visual Diagram for GKE Shared Responsibility Model 
```
          ┌───────────────────────────┐
          │        Google Cloud       │
          │ Control Plane & Infra     │
          │ Masters, Networking, LB  │
          └───────────────────────────┘
                      ▲
                      │
        ┌─────────────┴─────────────┐
        │         Customer           │
        │ Applications & Workloads   │
        │ Node Pools & Config        │
        │ Secrets, RBAC, Policies    │
        └───────────────────────────┘
```

## Key Takeaways
- GKE reduces operational burden: Google manages infrastructure and control plane
- Customers remain responsible for applications: Secure your workloads, configure nodes, manage access
- Understanding this model is essential for compliance, security audits, and proper cluster management. 