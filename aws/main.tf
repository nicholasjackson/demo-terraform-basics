variable "project" {
  description = "Name of the Azure resource group"
  default     = "terraform-basics-test"
}

variable "region" {
  description = "Region to deploy the resources"
  default     = "eu-west-1"
}

variable "gpu_enabled" {
  description = "Is the VM GPU enabled"
  default     = false
}

variable "machine" {
  description = "The machine type and image to use for the VM"
  # GPU instance with 24GB of memory and 4 vCPUs with 16GB of system RAM
  default = {
    "gpu" : { "type" : "g4dn.xlarge"},
    "cpu" : { "type" : "t3.micro"},
  }
}

variable "open_web_ui_user" {
  description = "Username to access the web UI"
  default     = "admin@demo.gs"
}

variable "openai_key" {
  description = "Optional API key to use OpenAI API with Ollama UI"
  default     = "" 
}

variable "ssh_pub_key" {
  description = "Public SSH key to be added to the VM"
  default     = ""
}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.59.0"
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

provider "aws" {
}