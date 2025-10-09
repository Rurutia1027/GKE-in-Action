variable "project_id" {
    description = "GCP project ID"
    type = string 
    default = "gcp-spring-devops"
}

variable "region" {
  description = "Region for all resources"
  default     = "us-central1"
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  default     = "gke-deep-dive"
}