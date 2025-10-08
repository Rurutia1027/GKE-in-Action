output "cluster_name" {
  value = google_container_cluster.gke_cluster.name
}

output "ingress_ip" {
  description = "Ingress external IP (after provisioning)"
  value       = kubernetes_ingress_v1.demo_ingress.status[0].load_balancer[0].ingress[0].ip
}