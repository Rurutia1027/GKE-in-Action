############################################################
# Provider Configuration
# Specify GCP project, region, and zone
############################################################

provider "google" {
  credentials = file("~/.gcp/gcp-spring-devops-d8e2a93fda07.json")
  project     = "gcp-spring-devops"
  region      = "us-central1"
  zone = "us-central1-a"
}