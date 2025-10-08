############################################################
# 5. Outputs
############################################################
output "ingress_ip" {
  description = "Ingress external IP"
  value       = try(kubernetes_ingress_v1.demo_ingress.status[0].load_balancer[0].ingress[0].ip, "Pending")
}

output "gke_cluster_name" {
  value = google_container_cluster.route_based_gke_cluster.name
}

output "gke_cluster_endpoint" {
  value = google_container_cluster.route_based_gke_cluster.endpoint
}