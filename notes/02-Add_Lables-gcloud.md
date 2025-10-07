# Add Lables to GKE Cluster 

### Command syntax 
```bash 
gcloud container clusters update <CLUSTER_NAME> \
   --region <REGION> \
   --update-labels key1=value1,key2=value2
```

### Example 
If your cluster name is gke-deep-dive and region is in `us-central1`:
```bash 
gcloud container clusters update gke-deep-dive \
  --region us-central1 \
  --update-labels env=dev,owner=emma,team=devops
```
This will add or update those labels on the cluster


### Remove Labels (optional)
To remove specific labels: 
```bash 
gcloud container clusters update gke-deep-dive \
   --region us-central1 \
   --remove-labels env,owner
```

### Important Notes 
- The `--update-labels` flag merges with existing labels (it doesn't overwrite all unless keys conflict).
- Changes made via `gcloud` will not appear in your Terraform configuraiton, so: 
> Either you also update your Terraform `main.tf` to include those labels (so it stays in sync)
> Or use Terraform to manage labels directly (via the resource "google_container_cluster" "..." block with a resource_labels field).
- You'll need the right IAM permissions: `roles/container.admin` or equivalent. 
