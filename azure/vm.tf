data "azurerm_platform_image" "openwebui" {
  location  = azurerm_resource_group.openwebui.location
  publisher = "Debian"
  offer     = "debian-11"
  sku       = "11"
}

resource "random_password" "password" {
  length           = 16
  special          = false
}

data "cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "init.sh"
    content_type = "text/x-shellscript"

    content = templatefile("${path.module}/scripts/provision_vars.sh",
    {
      open_webui_user = var.open_webui_user,
      open_webui_password = random_password.password.result,
      openai_base = var.openai_base,
      openai_key = var.openai_key,
      gpu_enabled = var.gpu_enabled,
    }) 
  }
  
  part {
    content_type = "text/cloud-config"
    content = file("${path.module}/scripts/init.yaml")
  }
}

resource "azurerm_resource_group" "openwebui" {
  name     = "example-resources"
  location = "West Europe"
}

resource "azurerm_virtual_network" "openwebui" {
  name                = "example-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.openwebui.location
  resource_group_name = azurerm_resource_group.openwebui.name
}

resource "azurerm_subnet" "openwebui" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.openwebui.name
  virtual_network_name = azurerm_virtual_network.openwebui.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.openwebui.address_space[0], 8, 2)]
}

resource "azurerm_public_ip" "openwebui" {
  name                = "openwebui-ip"
  location            = azurerm_resource_group.openwebui.location
  resource_group_name = azurerm_resource_group.openwebui.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "openwebui" {
  name                = "example-nic"
  location            = azurerm_resource_group.openwebui.location
  resource_group_name = azurerm_resource_group.openwebui.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.openwebui.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.openwebui.id
  }
}

resource "azurerm_linux_virtual_machine" "openwebui" {
  name                = "example-machine"
  resource_group_name = azurerm_resource_group.openwebui.name
  location            = azurerm_resource_group.openwebui.location
  size                = var.gpu_enabled ? var.machine.gpu.type : var.machine.cpu.type
  admin_username      = "openwebui"
  network_interface_ids = [
    azurerm_network_interface.openwebui.id,
  ]

  admin_ssh_key {
    username   = "openwebui"
    public_key = file("/tmp/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = data.azurerm_platform_image.openwebui.publisher
    offer     = data.azurerm_platform_image.openwebui.offer
    sku       = data.azurerm_platform_image.openwebui.sku
    version   = data.azurerm_platform_image.openwebui.version
  }

  custom_data = data.cloudinit_config.config.rendered
}

resource "terracurl_request" "openwebui" {
  lifecycle {
    replace_triggered_by = [ azurerm_linux_virtual_machine.openwebui ]
  }

  name   = "open_web_ui"
  url    = "http://${resource.azurerm_public_ip.openwebui.ip_address}"
  method = "GET"

  response_codes = [200]
  max_retry      = 120
  retry_interval = 10
}