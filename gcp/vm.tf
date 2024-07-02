# Create a random password for the web UI
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Create a private key for the provisioner user that is used byt the remote provisioner
resource "tls_private_key" "provisioner" {
  algorithm = "ED25519"
}

# Create a custom service account for the VM instance
resource "google_service_account" "ollama" {
  project      = var.project
  account_id   = "vm-service-account"
  display_name = "Custom SA for VM Instance"
}

# Create a boot disk for the VM
resource "google_compute_disk" "boot" {
  name    = "ollama-disk"
  type    = "pd-ssd"
  zone    = var.region
  project = var.project

  # Debian 11 with Nvidia CUDA 12.1 and Python 3.10
  image = var.image
  size  = 200
}

# Create the VM instance
resource "google_compute_instance" "ollama" {
  name         = "ollama"
  machine_type = var.gpu_enabled == "true" ? var.machine_type["gpu"] : var.machine_type["cpu"]
  zone         = var.region
  project      = var.project

  tags = ["terraform", "ssh", "ollama"]

  scheduling {
    on_host_maintenance = "TERMINATE"
  }

  boot_disk {
    source = resource.google_compute_disk.boot.id
  }

  network_interface {
    network = "default"

    access_config {}
  }

  metadata = {
    # Add ssh keys for the user and the remote provisioner
    ssh-keys = <<EOT
      ollama:${var.ssh_pub_key} ollama
      provisioner:${trimspace(resource.tls_private_key.provisioner.public_key_openssh)} provisioner
    EOT

    # Add the startup script that will install the web server and configure the web UI
    startup-script = templatefile("./scripts/init.sh", { open-webui-password = random_password.password.result, gpu_enabled = var.gpu_enabled })
  }

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.ollama.email
    scopes = ["cloud-platform"]
  }

  # This script will wait for the web server to be ready before Terraform continues
  # It curls the WebUI until it gets a response, the web ui is only available after the startup script has finished
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "provisioner"
      private_key = resource.tls_private_key.provisioner.private_key_pem
      host        = self.network_interface.0.access_config.0.nat_ip
    }

    inline = [
      "until curl -s -f -o /dev/null \"http://127.0.0.1\"",
      "do",
      "  sleep 5",
      "done"
    ]
  }
}

resource "google_compute_firewall" "ssh" {
  name    = "ssh-access"
  project = var.project
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags   = ["ssh"]
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "ollama" {
  name    = "olla-access"
  project = var.project
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  target_tags   = ["ollama"]
  source_ranges = ["0.0.0.0/0"]
}
