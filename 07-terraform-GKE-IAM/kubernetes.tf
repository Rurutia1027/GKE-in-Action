provider "kubernetes" {
  host                   = google_container_cluster.gke_deep_dive.endpoint
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(
    google_container_cluster.gke_deep_dive.master_auth[0].cluster_ca_certificate
  )
}

data "google_client_config" "default" {}

# -------------------------------
# Kubernetes Service Account mapped to GCP SA
# -------------------------------
resource "kubernetes_service_account" "ksa_gke_app" {
  metadata {
    name      = "ksa-gke-app"
    namespace = "default"
    annotations = {
      #!!!!!! GSA -> mapping -> KSA !!!! see notes of KSA_GSA_Core-Concept Review this note 
      "iam.gke.io/gcp-service-account" = google_service_account.gke_app_gsa.email
    }
  }
}

# -------------------------------
# Deployment
# -------------------------------
resource "kubernetes_deployment" "gke_deep_dive_app" {
  metadata {
    name = "gke-deep-dive-app"
    labels = { app = "online" }
  }

  spec {
    replicas = 2
    selector { match_labels = { app = "online" } }

    template {
      metadata { labels = { app = "online" } }

      spec {
        service_account_name = kubernetes_service_account.ksa_gke_app.metadata[0].name

        container {
          name  = "gke-deep-dive-app"
          image = "gcr.io/google-containers/echoserver:1.10"
          port {
            name           = "http"
            container_port = 8080
          }
          readiness_probe {
            http_get {
              path = "/healthz"
              port = 8080
            }
          }
        }
      }
    }
  }
}

# -------------------------------
# External LoadBalancer Service (L4 RBS)
# -------------------------------
resource "kubernetes_service" "gke_deep_dive_svc" {
  metadata {
    name = "gke-deep-dive-svc"
    annotations = {
      "cloud.google.com/l4-rbs" = "enabled"
    }
  }

  spec {
    type                    = "LoadBalancer"
    external_traffic_policy = "Cluster"
    selector = { app = "online" }

    port {
      name        = "tcp-port"
      protocol    = "TCP"
      port        = 8080
      target_port = 8080
    }
  }
}