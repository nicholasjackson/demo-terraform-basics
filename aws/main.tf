variable "project" {
  description = "Name of the Azure resource group"
  default     = "terraform-basics-test"
}

variable "region" {
  description = "Region to deploy the resources"
  default     = ""
}

variable "gpu_enabled" {
  description = "Is the VM GPU enabled"
  default     = false
}

variable "machine" {
  description = "The machine type and image to use for the VM"
  # GPU instance with 24GB of memory and 4 vCPUs with 16GB of system RAM
  default = {
    "gpu" : { "type" : "g4dn.xlarge", "script" : "scripts/provision.sh" },
    "cpu" : { "type" : "t3.micro", "script" : "scripts/provision.sh" },
  }
}

variable "open_webui_user" {
  description = "Username to access the web UI"
  default     = "admin@demo.gs"
}

variable "openai_base" {
  description = "Optional base URL to use OpenAI API with Open Web UI" 
  default     = "https://api.openai.com/v1"
}

variable "openai_key" {
  description = "Optional API key to use OpenAI API with Open Web UI"
  default     = ""
}

variable "ssh_pub_key" {
  description = "Public SSH key to be added to the VM"
  default     = ""
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.59.0"
    }
    terracurl = {
      source  = "devops-rob/terracurl"
      version = "1.2.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
  }
}

provider "aws" {
}
