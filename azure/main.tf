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
    "gpu" : { "type" : "g3s.xlarge", "version" : "debian-11-amd64-20240717-1811" }
    "cpu" : { "type" : "t2.large", "version" : "debian-11-amd64-20240717-1811" }
  }
}

variable "openai_key" {
  description = "Optional API key to use OpenAI API with open_web_ui UI"
  default     = ""
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
