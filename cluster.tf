

resource "google_container_cluster" "cluster" {
  name        = "${var.project}-k8s"
  location    = var.region
  description = "Kubernetes cluster for ${var.project}"

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  #cluster_ipv4_cidr = var.cluster_ipv4_cidr

  # VPC-native
  ip_allocation_policy {
    # cluster_secondary_range_name = # The name of the existing secondary range in the cluster's subnetwork to use for pod IP addresses.
    # services_secondary_range_name - (Optional) The name of the existing secondary range in the cluster's subnetwork to use for service ClusterIPs. 
    # Alternatively, services_ipv4_cidr_block can be used to automatically create a GKE-managed one.

    cluster_ipv4_cidr_block  = "10.192.0.0/14"
    services_ipv4_cidr_block = "10.196.0.0/14"
  }

  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  # Setting an empty username and password explicitly disables basic auth
  master_auth {
    username = ""
    password = ""
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "XXX.201.153.118"
      display_name = "H"
    }
  }

  addons_config {
    network_policy_config {
      disabled = "false"
    }
    horizontal_pod_autoscaling {
      disabled = "false"
    }
    istio_config {
      disabled = "false"
    }
    cloudrun_config {
      disabled = "false"
    }
    dns_cache_config {
      enabled = "true"
    }
  }

  # network = "" 
  # subnetwork = ""

  network_policy {
    enabled  = "true"
    provider = "CALICO"
  }

  # pod_security_policy_config {}

  resource_labels = {
    "Project" = var.project
  }

  workload_identity_config {}

  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }
}

resource "google_container_node_pool" "general_purpose" {
  name     = "${var.project}-k8s-general"
  location = var.region
  cluster  = google_container_cluster.cluster.name

  management {
    auto_repair  = "true"
    auto_upgrade = "true"
  }

  autoscaling {
    min_node_count = var.general_purpose_min_node_count
    max_node_count = var.general_purpose_max_node_count
  }
  initial_node_count = var.general_purpose_min_node_count

  node_config {
    disk_size_gb = "20GB"
    disk_type    = "pd-ssd"
    machine_type = var.general_purpose_machine_type
    # image-type

    labels = {
      "node-pool" = "general"
    }

    metadata = {
      disable-legacy-endpoints = "true"
    }

    # Needed for correctly functioning cluster, see 
    # https://www.terraform.io/docs/providers/google/r/container_cluster.html#oauth_scopes
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only"
    ]

    preemptible = false

    tags = ["${var.project}-k8s-general", "k8s-nodes"]

  }
}

# The following outputs allow authentication and connectivity to the GKE Cluster
# by using certificate-based authentication.
output "client_certificate" {
  value = google_container_cluster.cluster.master_auth.0.client_certificate
}

output "client_key" {
  value = google_container_cluster.cluster.master_auth.0.client_key
}

output "cluster_ca_certificate" {
  value = google_container_cluster.cluster.master_auth.0.cluster_ca_certificate
}
