# -------------------------------
# 1️⃣ Create a subnet
# -------------------------------
resource "google_compute_subnetwork" "gke_deep_dive_subnet" {
  name          = "gke-deep-dive-subnet"
  ip_cidr_range = "10.10.0.0/24"
  region        = var.region
  network       = "default"
}

# -------------------------------
# 2️⃣ GKE Cluster (VPC-native, Workload Identity enabled)
# -------------------------------
resource "google_container_cluster" "gke_deep_dive" {
  name     = var.cluster_name
  location = var.region
  remove_default_node_pool = true
  initial_node_count       = 1

  networking_mode = "VPC_NATIVE"
  subnetwork      = google_compute_subnetwork.gke_deep_dive_subnet.self_link
  ip_allocation_policy {}

  addons_config {
    http_load_balancing { disabled = false }
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}

# -------------------------------
# 3️⃣ Node Pool
# -------------------------------
resource "google_container_node_pool" "primary_nodes" {
  name       = "gke-deep-dive-node-pool"
  cluster    = google_container_cluster.gke_deep_dive.name
  location   = var.region

  node_config {
    machine_type = "e2-medium"
    disk_type    = "pd-standard"
    disk_size_gb = 10
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  initial_node_count = 1
}

# -------------------------------
# 4️⃣ GCP Service Account for Workload Identity
# -------------------------------
resource "google_service_account" "gke_app_gsa" {
    account_id = "gke-deep-dive-app"
    display_name = "GKE Deep Dive App GSA"
}

# Grant IAM role for Workload Identity usage 
resource "google_service_account_iam_binding" "ksa_to_gsa" {
    service_account_id = google_service_account.gke_app_gsa.name 
    role = "roles/iam.workloadIdentityUser"

    members = [
        "serviceAccount:${var.project_id}.svc.id.goog[default/ksa-gke-app]"
    ]
}

# Optional: Grant Storage Viewer for demo 
resource "google_project_iam_binding" "gsa_storage_viewer" {
    project = var.project_id
    role = "roles/storage.objectViewer"

    members = [
        "serviceAccount:${google_service_account.gke_app_gsa.email}"
    ]
}
