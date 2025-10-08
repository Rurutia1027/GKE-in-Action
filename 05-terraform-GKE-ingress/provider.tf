############################################################
# ROUTE-BASED GKE CLUSTER (Legacy Networking)
# Simple, legacy style - GKE assigns Pod CIDRs interally
# no secondary ranges or custom subnet needed. 
############################################################

provider "google" {
  credentials = file("~/.gcp/gcp-spring-devops-d8e2a93fda07.json")
  project     = "gcp-spring-devops"
  region      = "us-central1"
}