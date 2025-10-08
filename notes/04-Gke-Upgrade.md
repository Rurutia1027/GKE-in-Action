# GKE Upgrade Scenario 
Image you have a GKE cluster running production workloads: 
- Cluster: gke-deep-dive in us-central1
- Node pool: default-pool with nodes running 1.26.0-gke.100
- Application pods running in Deployments

You want to upgrade the cluster nodes to a new GKE version (1.27.x) without downtime. 

### Scenario steps: 
- **Check available GKE versions**: Make sure the target version is available for your cluster. 
- Upgrade node pool with surge upgrades/blue-green style:
> GKE will create new nodes with the new version
> Evict pods from old ones.
> Move workloads onto upgraded nodes
> Delete old nodes after pods are running safely
- Pods are automaticaly rescheduled, so application stays available 

### Blue/Green Upgrade in GKE 
- Blue/Green Nodes: The cluster temporarily has two sets of nodes:
> Blue nodes: old version 
> Green nodes: new version 

- Process:
> GKE creates "green" nodes with the upgraded version
> Pods are drained from "blue" nodes and moved to "green" nodes
> Once all pods are running on "green", GKE deletes "blue" nodes

- Benefits
> Zero downtime upgrade
> Rolling migration ensures workloads stay available 
> Easy rollback if issues arise (before old nodes are deleted)

Note: Blue/Green here is for nodes, not your application pods. Application-level blue/green deployments are separate and managed at Deployment level.


### Correspoinding gcloud Commands 

- Check cluster and node pool version 
- Check available GKE versions 
- Upgrade the cluster control plane (optional)
- Upgrade node pool with surge upgrade (blue/green style)