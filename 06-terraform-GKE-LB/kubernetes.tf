# Configure Kubernetes provider
provider "kubernetes" {
  host  = google_container_cluster.gke_deep_dive_vpc_native.endpoint
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(
    google_container_cluster.gke_deep_dive_vpc_native.master_auth[0].cluster_ca_certificate
  )
}

data "google_client_config" "default" {}

# -------------------------------
# 1️⃣  Deployment (echoserver)
# -------------------------------
resource "kubernetes_deployment" "gke_deep_dive_app" {
  metadata {
    name = "gke-deep-dive-app"
    labels = {
      app = "online"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "online"
      }
    }

    template {
      metadata {
        labels = {
          app = "online"
        }
      }

      spec {
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
# 2️⃣  External LoadBalancer Service
# -------------------------------
resource "kubernetes_service" "gke_deep_dive_svc" {
  metadata {
    name = "gke-deep-dive-svc"
    annotations = {
      "cloud.google.com/l4-rbs" = "enabled"
    }
  }

  spec {
    selector = {
      app = "online"
    }

    type = "LoadBalancer"
    external_traffic_policy = "Cluster"

    port {
      name        = "tcp-port"
      protocol    = "TCP"
      port        = 8080
      target_port = 8080
    }
  }
}