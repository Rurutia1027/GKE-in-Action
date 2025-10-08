output "gke_cluster_name" {
  value = google_container_cluster.route_based_gke_cluster.name
}

output "gke_cluster_endpoint" {
  value = google_container_cluster.route_based_gke_cluster.endpoint
}