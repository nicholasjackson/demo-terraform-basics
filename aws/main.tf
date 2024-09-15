variable "region" {
  description = "The AWS region to deploy the VM"
  default     = "eu-central-1"
}

variable "gpu_enabled" {
  description = "Is the VM GPU enabled"
  default     = false
}

variable "machine" {
  description = "The machine type and image to use for the VM"
  # GPU instance with 24GB of memory and 4 vCPUs with 16GB of system RAM
  default = {
    "gpu" : { "type" : "g4dn.xlarge" },
    "cpu" : { "type" : "t3.micro" },
  }
}

variable "custom_ami" {
  description = "The custom AMI to use for the VM, if not provided the latest Debian 11 AMI will be used"
  default     = ""
}

variable "provision_script" {
  description = <<EOF
    Path to the script to provision the VM, use scripts/provision_vars.sh 
    when using a base image such as debian.

    When using the custom AMI built by Packer from this repository, you can 
    use the path to the scripts/configure.sh that only sets the required 
    environment variables.
  EOF

  default     = "scripts/provision_vars.sh"
}

variable "ami_name" {
  description = "The name of the AMI to use for the VM, default is the latest Debian 11 AMI"

  default = "debian-11-amd64-*"
}

variable "ami_owners" {
  description = "The owners of the AMI to use for the VM, default is the official Debian AMI"

  default = ["136693071363"]
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
