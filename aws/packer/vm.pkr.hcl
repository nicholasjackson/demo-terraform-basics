packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

variable "aws_access_key" {
  type = string
}

// export PKR_VAR_aws_secret_key=$YOURSECRETKEY
variable "aws_secret_key" {
  type = string
}

variable "region" {
  type    = string
  default = "eu-central-1"
}

data "amazon-ami" "debian" {
  filters = {
    virtualization-type = "hvm"
    name                = "debian-11-amd64-*"
    root-device-type    = "ebs"
  }
  owners      = ["136693071363"]
  most_recent = true
  # Access Region Configuration
  region = var.region
}

source "amazon-ebs" "open-webui" {
  access_key    = var.aws_access_key
  secret_key    = var.aws_secret_key
  region        = var.region
  source_ami    = data.amazon-ami.debian.id
  instance_type = "t2.micro"
  ssh_username  = "admin"
  ami_name      = "open_webui_{{timestamp}}"

  launch_block_device_mappings {
    device_name           = "/dev/xvda"
    delete_on_termination = true
    volume_type           = "gp2"
    volume_size           = 60
  }
}

build {
  sources = [
    "source.amazon-ebs.open-webui"
  ]

  provisioner "file" {
    source      = "scripts/provision.sh"
    destination = "/tmp/provision.sh"
  }

  provisioner "shell" {
    inline = ["sudo bash /tmp/provision.sh"]
  }
}