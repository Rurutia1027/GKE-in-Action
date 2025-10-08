############################################################
# outputs.tf
# Print useful information after Terraform apply
############################################################

# Bastion host public IP (for SSH access)
output "bastion_public_ip" {
  description = "Public IP of the Bastion host (SSH access point)"
  value = google_compute_instance.bastion.network_interface[0].network_ip
}

# Private GKE cluster name
output "private_gke_cluster_name" {
  description = "Name of the private GKE cluster"
  value       = google_container_cluster.private_cluster.name
}

# GKE cluster endpoint (private master)
output "private_gke_master_endpoint" {
  description = "Private IP of the GKE master endpoint"
  value       = google_container_cluster.private_cluster.endpoint
}

# Reminder message for connecting via Bastion SSH
output "bastion_ssh_instructions" {
  description = "Example command to SSH into the Bastion host"
  value       = "ssh -i ~/.ssh/id_rsa your-username@${google_compute_instance.bastion.network_interface[0].access_config[0].nat_ip}"
}

# Reminder message for SSH tunnel to access kubectl locally
output "kubectl_ssh_tunnel_instructions" {
  description = "Example command to create SSH tunnel for local kubectl"
  value       = "ssh -i ~/.ssh/id_rsa -L 6443:<private-master-ip>:6443 your-username@${google_compute_instance.bastion.network_interface[0].access_config[0].nat_ip}"
}