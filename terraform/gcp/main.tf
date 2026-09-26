terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket      = "sinsamersuk-homelab-tfstate"
    prefix      = "terraform/state/gcp"
    credentials = "credentials.json"
  }
}

provider "google" {
  project     = "sinsamersuk"
  region      = "asia-southeast1"
  credentials = fileexists("${path.module}/credentials.json") ? file("${path.module}/credentials.json") : null
}
