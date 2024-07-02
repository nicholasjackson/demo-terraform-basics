variable "project" {
  description = "Name of the GPC project"
  default = "terraform-basics-test"
}

variable "region" {
  description = "Region to deploy the resources"
  default = "europe-west1-b"
}

variable "machine_type" {
  description = "The machine type to use for the VM"
  # GPU instance with 24GB of memory and 4 vCPUs with 16GB of system RAM
  default     = {
    "gpu": "g2-standard-4" 
    "cpu": "n1-standard-4"
  }
}

variable "gpu_enabled" {
  description = "Is the VM GPU enabled"
  default = false
}

variable "image" {
  description = "The image to use for the VM"

  # Debian 11 with Nvidia CUDA 12.1
  #default = "deeplearning-platform-release/common-cu121-debian-11-py310"
  default = "debian-11-bullseye-v20240611"
}

variable "open_web_ui_user" {
  description = "Username to access the web UI"
  default = "admin@demo.gs"
}

variable "ssh_pub_key" {
  description = "Public SSH key to be added to the VM"
  default = ""
}

terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "5.35.0"
    }
  }
}

provider "google" {
  # ensure the environment variable GOOGLE_CREDENTIALS is set with 
  # your service account json
}