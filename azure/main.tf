variable "project" {
  description = "Name of the Azure resource group"
  default     = "terraform-basics-test"
}

variable "region" {
  description = "Region to deploy the resources"
  default     = "West Europe"
}

variable "gpu_enabled" {
  description = "Is the VM GPU enabled"
  default     = true
}

variable "machine" {
  description = "The machine type and image to use for the VM"
  # GPU instance with 24GB of memory and 4 vCPUs with 16GB of system RAM
  default = {
    "gpu" : { "type" : "Standard_NC4as_T4_v3", "publisher" : "Debian", offer : "Debian-11", sku : "11-backports-gen2", version : "latest" },
    "cpu" : { "type" : "Standard_DS1_v2", "image" : "debian-11-bullseye-v20240611" }
  }
}

variable "open_web_ui_user" {
  description = "Username to access the web UI"
  default     = "admin@demo.gs"
}

variable "ssh_pub_key" {
  description = "Public SSH key to be added to the VM"
  default     = ""
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.112.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.3.4"
    }
    terracurl = {
      source  = "devops-rob/terracurl"
      version = "1.2.1"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "vm" {
  name     = var.project
  location = var.region
}
