data "http" "my_ip" {
  url = "https://api.ipify.org"
}

locals {
  # my_ip      = chomp(data.http.my_ip.response_body)
  # my_ip_cidr = "${local.my_ip}/32"
  my_ip      = "0.0.0.0"
  my_ip_cidr = "${local.my_ip}/0"
}

// resource group
resource "azurerm_resource_group" "rg_k8s_learning" {
  name     = "rg-k8s-learning"
  location = var.location
}


// virtual network
resource "azurerm_virtual_network" "vnet_k8s_learning" {
  name                = "vnet-k8s-learning"
  location            = azurerm_resource_group.rg_k8s_learning.location
  resource_group_name = azurerm_resource_group.rg_k8s_learning.name
  address_space       = ["10.0.0.0/16"]
}


// subnet 0
resource "azurerm_subnet" "subnet_0_k8s_learning" {
  name                 = "subnet_0_k8s_learning"
  resource_group_name  = azurerm_resource_group.rg_k8s_learning.name
  virtual_network_name = azurerm_virtual_network.vnet_k8s_learning.name

  address_prefixes = ["10.0.0.0/24"]
}

// network security groupe for subnet 0
resource "azurerm_network_security_group" "nsg_0_k8s_learning" {
  name                = "nsg_0_k8s_learning"
  location            = azurerm_resource_group.rg_k8s_learning.location
  resource_group_name = azurerm_resource_group.rg_k8s_learning.name
}

// network security rule for subnet 0 - Allow ssh inbound from user IP
resource "azurerm_network_security_rule" "nsr_0_k8s_learning" {
  name                        = "AllowSSH"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = local.my_ip_cidr
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg_k8s_learning.name
  network_security_group_name = azurerm_network_security_group.nsg_0_k8s_learning.name
}

// network security group association for subnet 0
resource "azurerm_subnet_network_security_group_association" "nsg_association_0_k8s_learning" {
  subnet_id                 = azurerm_subnet.subnet_0_k8s_learning.id
  network_security_group_id = azurerm_network_security_group.nsg_0_k8s_learning.id
}


// subnet 1
resource "azurerm_subnet" "subnet_1_k8s_learning" {
  name                 = "subnet_1_k8s_learning"
  resource_group_name  = azurerm_resource_group.rg_k8s_learning.name
  virtual_network_name = azurerm_virtual_network.vnet_k8s_learning.name
  address_prefixes     = ["10.0.1.0/24"]
}

// network security groupe subnet 1
resource "azurerm_network_security_group" "nsg_1_k8s_learning" {
  name                = "nsg_1_k8s_learning"
  location            = azurerm_resource_group.rg_k8s_learning.location
  resource_group_name = azurerm_resource_group.rg_k8s_learning.name
}

// network security rule for subnet 1 - Allow ssh inbound from user IP
resource "azurerm_network_security_rule" "nsr_1_k8s_learning" {
  name                        = "AllowSSH"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = local.my_ip_cidr
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg_k8s_learning.name
  network_security_group_name = azurerm_network_security_group.nsg_1_k8s_learning.name
}

// network security group association for subnet 1
resource "azurerm_subnet_network_security_group_association" "nsg_association_1_k8s_learning" {
  subnet_id                 = azurerm_subnet.subnet_1_k8s_learning.id
  network_security_group_id = azurerm_network_security_group.nsg_1_k8s_learning.id
}


// public ip for host 0
resource "azurerm_public_ip" "pip_host_0_k8s_learning" {
  name                = "pip_host_0_k8s_learning"
  resource_group_name = azurerm_resource_group.rg_k8s_learning.name
  location            = azurerm_resource_group.rg_k8s_learning.location
  sku                 = "Standard"
  allocation_method   = "Static"
}

// network interface card for host 0
resource "azurerm_network_interface" "nic_host_0_k8s_learning" {
  name                = "nic_host_0_k8s_learning"
  location            = azurerm_resource_group.rg_k8s_learning.location
  resource_group_name = azurerm_resource_group.rg_k8s_learning.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_0_k8s_learning.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip_host_0_k8s_learning.id
  }
}

// host 0
resource "azurerm_linux_virtual_machine" "vm_host_0_k8s_learning" {
  name                            = "vm_host_0_k8s_learning"
  computer_name                   = "vm-host-0"
  resource_group_name             = azurerm_resource_group.rg_k8s_learning.name
  location                        = azurerm_resource_group.rg_k8s_learning.location
  size                            = "Standard_B1s"
  disable_password_authentication = false
  admin_username                  = var.username_host_0
  admin_password                  = var.password_host_0

  network_interface_ids = [
    azurerm_network_interface.nic_host_0_k8s_learning.id,
  ]

  # admin_ssh_key {
  #   username   = var.username_host_0
  #   public_key = file("~/.ssh/id_rsa.pub")
  # }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

// public ip for host 1
resource "azurerm_public_ip" "pip_host_1_k8s_learning" {
  name                = "pip_host_1_k8s_learning"
  resource_group_name = azurerm_resource_group.rg_k8s_learning.name
  location            = azurerm_resource_group.rg_k8s_learning.location
  sku                 = "Standard"
  allocation_method   = "Static"
}

// network interface card for host 1
resource "azurerm_network_interface" "nic_host_1_k8s_learning" {
  name                = "nic_host_1_k8s_learning"
  location            = azurerm_resource_group.rg_k8s_learning.location
  resource_group_name = azurerm_resource_group.rg_k8s_learning.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_1_k8s_learning.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip_host_1_k8s_learning.id
  }
}

// host 1
resource "azurerm_linux_virtual_machine" "vm_host_1_k8s_learning" {
  name                            = "vm_host_1_k8s_learning"
  computer_name                   = "vm-host-1"
  resource_group_name             = azurerm_resource_group.rg_k8s_learning.name
  location                        = azurerm_resource_group.rg_k8s_learning.location
  size                            = "Standard_B1s"
  disable_password_authentication = false
  admin_username                  = var.username_host_1
  admin_password                  = var.password_host_1

  network_interface_ids = [
    azurerm_network_interface.nic_host_1_k8s_learning.id,
  ]

  # admin_ssh_key {
  #   username   = var.username_host_1
  #   public_key = file("~/.ssh/id_rsa.pub")
  # }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}