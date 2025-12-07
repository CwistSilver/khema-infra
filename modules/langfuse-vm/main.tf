terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# Resource Group for Langfuse
resource "azurerm_resource_group" "langfuse" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "langfuse" {
  name                = "vnet-langfuse"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.langfuse.location
  resource_group_name = azurerm_resource_group.langfuse.name
  tags                = var.tags
}

# Subnet
resource "azurerm_subnet" "langfuse" {
  name                 = "snet-langfuse"
  resource_group_name  = azurerm_resource_group.langfuse.name
  virtual_network_name = azurerm_virtual_network.langfuse.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Public IP
resource "azurerm_public_ip" "langfuse" {
  name                = "pip-langfuse"
  location            = azurerm_resource_group.langfuse.location
  resource_group_name = azurerm_resource_group.langfuse.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Network Security Group
resource "azurerm_network_security_group" "langfuse" {
  name                = "nsg-langfuse"
  location            = azurerm_resource_group.langfuse.location
  resource_group_name = azurerm_resource_group.langfuse.name

  # SSH
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # HTTP
  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # HTTPS
  security_rule {
    name                       = "HTTPS"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Langfuse Web (3000)
  security_rule {
    name                       = "Langfuse-Web"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# Network Interface
resource "azurerm_network_interface" "langfuse" {
  name                = "nic-langfuse"
  location            = azurerm_resource_group.langfuse.location
  resource_group_name = azurerm_resource_group.langfuse.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.langfuse.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.langfuse.id
  }

  tags = var.tags
}

# Associate NSG with NIC
resource "azurerm_network_interface_security_group_association" "langfuse" {
  network_interface_id      = azurerm_network_interface.langfuse.id
  network_security_group_id = azurerm_network_security_group.langfuse.id
}

# Cloud-init script to install Docker and setup Langfuse
locals {
  cloud_init = templatefile("${path.module}/cloud-init.yaml", {
    postgresql_host     = var.postgresql_host
    postgresql_username = var.postgresql_admin_username
    postgresql_password = var.postgresql_admin_password
    salt                = var.langfuse_secret_salt
    nextauth_secret     = var.nextauth_secret
    public_ip           = azurerm_public_ip.langfuse.ip_address
  })
}

# Virtual Machine
resource "azurerm_linux_virtual_machine" "langfuse" {
  name                = "vm-langfuse"
  location            = azurerm_resource_group.langfuse.location
  resource_group_name = azurerm_resource_group.langfuse.name
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.langfuse.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(local.cloud_init)

  tags = var.tags
}
