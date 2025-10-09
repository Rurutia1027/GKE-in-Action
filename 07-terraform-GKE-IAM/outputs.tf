output "cluster_name" {
  value = google_container_cluster.gke_deep_dive.name
}

output "kubernetes_endpoint" {
  value = google_container_cluster.gke_deep_dive.endpoint
}

output "loadbalancer_ip" {
  value = kubernetes_service.gke_deep_dive_svc.status[0].load_balancer[0].ingress[0].ip
}