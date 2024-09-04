data "google_compute_image" "debian" {
  family  = var.gpu_enabled ? var.machine.gpu.family : var.machine.cpu.family
  project = var.gpu_enabled ? var.machine.gpu.project : var.machine.cpu.project
}

# Create a random password for the web UI
resource "random_password" "password" {
  length           = 16
  special          = false
}

# Create a custom service account for the VM instance
resource "google_service_account" "openwebui" {
  account_id   = "vm-service-account"
  display_name = "Custom SA for VM Instance"
}

# Create the VM instance
resource "google_compute_instance" "openwebui" {
  name         = "openwebui"
  machine_type = var.gpu_enabled == true ? var.machine.gpu.type : var.machine.cpu.type
  zone         = var.region

  tags = ["terraform", "ssh", "http"]

  scheduling {
    on_host_maintenance = "TERMINATE"
  }

  boot_disk {
    initialize_params {
      size = 200
      image = data.google_compute_image.debian.self_link
    }
  }

  network_interface {
    network = "default"

    access_config {}
  }

  metadata = {
    # Add ssh keys for the user
    ssh-keys = "openwebui:${file(var.ssh_pub_key)} openwebui"

    # Add the startup script that will install the web server and configure the web UI
    startup-script = templatefile(
      "./scripts/provision_vars.sh", 
      { 
        open_webui_user = var.open_webui_user,
        open_webui_password = random_password.password.result,
        openai_base = var.openai_base,
        openai_key = var.openai_key,
        gpu_enabled = var.gpu_enabled 
      })
  }

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.openwebui.email
    scopes = ["cloud-platform"]
  }
}

resource "terracurl_request" "openwebui" {
  name = "openwebui"
  url = "http://${google_compute_instance.openwebui.network_interface.0.access_config.0.nat_ip}"
  method = "GET"

  response_codes = [200]
  max_retry      = 120
  retry_interval = 10
}

resource "google_compute_firewall" "http" {
  name    = "http-access"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  target_tags   = ["http"]
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "ssh" {
  name    = "ssh-access"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags   = ["ssh"]
  source_ranges = ["0.0.0.0/0"]
}