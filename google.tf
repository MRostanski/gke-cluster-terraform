terraform {
  backend "gcs" {
    bucket      = "gke-from-scratch-terraform-state"
    prefix      = "terraform"
    credentials = "account.json"
  }
}

provider "google" {
  credentials = file("account.json")
  project     = var.project
  region      = var.region
}

