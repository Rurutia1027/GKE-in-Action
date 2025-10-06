# Notes - Syncing gcloud, Terraform & GKE Contexts 
## Goal 
Keep your gcloud CLI, Terraform provider, and kubectl context aligned to the same project and service account to avoid Permission denied or wrong-project erros. 


## Step 1 Activate the corect service account 
Use your JSON key file to authenticate your local gcloud CLI.
```bash 
gcloud auth activate-service-account \
    terraform-gcp-admin@gcp-spring-devops.iam.gserviceaccount.com \
    --key-file ~/.gcp/gcp-spring-devops.json 
```

- What this does: Activate the credentials so gcloud uses the same identity as Terraform. 

## Step 2 Set the active project 

```bash 
gcloud config set project gcp-spring-devops
```

- What this does: Ensures all gcloud and kubectl commands target the same GCP project

## Step 3 Verify your configuration 

```bash 
gcloud auth list 
gcloud config list
```

You should see:

```bash
ACTIVE: * terraform-gcp-admin@gcp-spring-devops.iam.gserviceaccount.com
project = gcp-spring-devops
```


## Step 4: Verify access to GKE clusters 
```bash 
gcloud container clusters list --region us-central1
```

If it lists your cluster (e.g., gke-deep-dive), then permissions and project are correctly set. 

## Step 5: Connect kubectl to the GKE cluster

```bash 
gcloud container clusters get-credentials gke-deep-dive \
  --region us-central1 \
  --project gcp-spring-devops
```

Then test connection: 
```bash 
kubectl get nodes
```
- What it does: Automatically writes your GKE credentials into `~/.kube/config`, allowing `kubectl` to talk directly with the remote cluster. 

## Step 6 Optional -- create a separate config for each project 
If you often swtich between projects: 
```bash 
gcloud config configurations create gcp-spring 
gcloud config set account terraform-gcp-admin@gcp-spring-devops.iam.gserviceaccount.com
gcloud config set project gcp-spring-devops
gcloud config activate gcp-spring
```

Then later you can switch back easily: 
```bash 
gcloud config configurations list 
gcloud confi gconfigurations activate <name>
```