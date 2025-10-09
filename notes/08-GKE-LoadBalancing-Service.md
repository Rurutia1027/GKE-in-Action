# Brief Introduction: Terraform Scripts for GKE Load Balancing Service

These Terraform scripts are designed to provision a Google Kubernentes Engine(GKE) cluster and deploy a simple application exposed via external or internal load balancing services. 

## What the Scripts Do
- The cluster uses alias IPs for pods and services, enabling efficient networking and automatic IP management. 
- A node pool is added for running application pods. 

### Creates a VPC-native GKE Cluster
- A lightweight application (like an echo server) is deployed using a Kubernetes Deployment.
- Multiple replicas ensure redundancy and allow the load balancer to distribute traffic across pods.

### Deploy an Application 
- A LoadBalancer Service is created to allow external traffic to reach the application.
- The annotation cloud.google.com/14-rbs: "enabled" tells GKE to create a backend-service-based Network Load Balancer (L4).
- Optionally, an internal load balancer can be configured to restrict traffic to within the VPC.

### Why This Matters 
- Using a single load balancing service allows multiple services or paths to share one external IP, saving cost and simplifying management.
- Terraform automates all steps: creating the cluster, node pool, deployments, and load balancers. This ensure the setup is repeatable, version-controlled, and easy to modify.
- Beginners can learn both Kubernnetes networking concepts (Service types, pods, replicas) and cloud load balancing concepts (external vs internal LB) in a hands-on way. 