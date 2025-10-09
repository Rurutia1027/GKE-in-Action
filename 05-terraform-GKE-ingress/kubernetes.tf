# gcloud container clusters get-credentials route-based-cluster --region us-central1 --project gcp-spring-devops
# then, kubectl get nodes can work 

############################################################
# Kubernetes Provider
############################################################
provider "kubernetes" {
  host = "https://${google_container_cluster.route_based_gke_cluster.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.route_based_gke_cluster.master_auth[0].cluster_ca_certificate)
}

data "google_client_config" "default" {}

############################################################
# 1. Namespace
############################################################
resource "kubernetes_namespace" "demo" {
  metadata {
    name = "ingress-demo"
  }x
}

############################################################
# 2. Frontend Deployment + Service
############################################################
resource "kubernetes_deployment" "frontend" {
  metadata {
    name      = "frontend"
    namespace = kubernetes_namespace.demo.metadata[0].name
    labels    = { app = "frontend" }
  }

  spec {
    replicas = 1
    selector { match_labels = { app = "frontend" } }

    template {
      metadata { labels = { app = "frontend" } }
      spec {
        container {
          name  = "frontend"
          image = "nginxdemos/hello"
          port { container_port = 80 }
        }
      }
    }
  }
}

resource "kubernetes_service" "frontend" {
  metadata {
    name      = "frontend-service"
    namespace = kubernetes_namespace.demo.metadata[0].name
  }

  spec {
    selector = { app = "frontend" }
    port {
      port        = 80          # Service port
      target_port = 80          # Must match container port
    }
    type = "ClusterIP"          # Correct type for Ingress
  }
}

############################################################
# 3. API Deployment + Service
############################################################
resource "kubernetes_deployment" "api" {
  metadata {
    name      = "api"
    namespace = kubernetes_namespace.demo.metadata[0].name
    labels    = { app = "api" }
  }

  spec {
    replicas = 1
    selector { match_labels = { app = "api" } }

    template {
      metadata { labels = { app = "api" } }
      spec {
        container {
          name  = "api"
          image = "hashicorp/http-echo"
          args  = ["-text=Hello from API"]
          port { container_port = 5678 }
        }
      }
    }
  }
}

resource "kubernetes_service" "api" {
  metadata {
    name      = "api-service"
    namespace = kubernetes_namespace.demo.metadata[0].name
  }

  spec {
    selector = { app = "api" }
    port {
      port        = 5678          # Service port matches container port
      target_port = 5678
    }
    type = "ClusterIP"            # Correct for Ingress
  }
}

############################################################
# 4. Ingress Resource
############################################################
resource "kubernetes_ingress_v1" "demo_ingress" {
  metadata {
    name      = "demo-ingress"
    namespace = kubernetes_namespace.demo.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class" = "gce"
    }
  }

  spec {
    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.frontend.metadata[0].name
              port { number = 80 }
            }
          }
        }
        path {
          path      = "/api"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.api.metadata[0].name
              port { number = 5678 }
            }
          }
        }
      }
    }
  }
}
