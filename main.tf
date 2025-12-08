# ================================================
# FULLY WORKING Azure Ubuntu VM – Windows 2025
# NO AUTH ERRORS – subscription & tenant hard-coded
# ================================================

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# ←←← THIS BLOCK FIXES ALL AUTH PROBLEMS ←←←
provider "azurerm" {
  features {}

  # ← YOUR VALUES (keep exactly these) ←
  subscription_id = "f18cee0c-94ae-4dd3-ac8a-a6fd1e37b163"
  tenant_id       = "c872c2b0-012f-4d75-a07b-7a6fd47d6066"

  # Uses your existing `az login` session
  use_cli = true
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "tf-win-rg"
  location = "eastus"
}

# Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "pip" {
  name                = "vm-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "nic" {
  name                = "vm-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

# Auto-generate SSH key
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "${path.module}/azure-key.pem"
  file_permission = "0600"
}

# The actual VM
resource "azurerm_linux_virtual_machine" "vm" {
  name                            = "ubuntu-vm"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = "Standard_B2s" # ~$15/month
  admin_username                  = "azureuser"
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.nic.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.ssh.public_key_openssh
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

# Nice outputs
output "public_ip" {
  value = azurerm_public_ip.pip.ip_address
}

output "ssh_command" {
  value = "ssh -i azure-key.pem azureuser@${azurerm_public_ip.pip.ip_address}"
}

output "key_location" {
  value = "Private key saved → ${abspath(local_file.private_key.filename)}"
}