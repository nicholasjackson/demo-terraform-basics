# Create a random password for the web UI
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Create a private key for the provisioner user that is used byt the remote provisioner
resource "tls_private_key" "provisioner" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_virtual_network" "main" {
  name                = "vm-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.vm.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "ollama" {
  name                = "ollama-ip"
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "ollama" {
  name                = "ollama-nic"
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name

  ip_configuration {
    name                          = "ollamaconfiguration1"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ollama.id
  }
}

locals {
  image_details = var.gpu_enabled == true ? var.machine.gpu : var.machine.cpu
}

data "cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "init.sh"
    content_type = "text/x-shellscript"

    content = templatefile("./scripts/init.sh", { gpu_enabled = var.gpu_enabled, open_webui_password = random_password.password.result })
  }

  part {
    content_type = "text/cloud-config"
    content = templatefile("./scripts/init.yaml", {
      provisioner_ssh_key = tls_private_key.provisioner.public_key_openssh
      ollama_ssh_key      = var.ssh_pub_key
      openai_key         = var.openai_key
    })
  }
}

resource "azurerm_virtual_machine" "ollama" {
  name                  = "ollama"
  location              = azurerm_resource_group.vm.location
  resource_group_name   = azurerm_resource_group.vm.name
  network_interface_ids = [azurerm_network_interface.ollama.id]
  vm_size               = local.image_details.type

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = local.image_details.publisher
    offer     = local.image_details.offer
    sku       = local.image_details.sku
    version   = local.image_details.version
  }

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "ollama"
    admin_username = "ollama"

    custom_data = data.cloudinit_config.config.rendered
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/ollama/.ssh/authorized_keys"
      key_data = var.ssh_pub_key
    }
  }

  tags = {
    firewall = "ssh"
  }
}

# Create a terracurl request to check if the web server is up and running
# Wait a max of 20 minutes with a 10 second interval
resource "terracurl_request" "ollama" {
  depends_on = [ azurerm_virtual_machine.ollama ]
  
  name = "ollama"
  url = "http://${azurerm_public_ip.ollama.ip_address}"
  method = "GET"

  response_codes = [200]
  max_retry      = 120
  retry_interval = 10
}
