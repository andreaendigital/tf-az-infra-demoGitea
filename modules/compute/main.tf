# Public IP for VM (Static allocation for stable SSH access)
resource "azurerm_public_ip" "vm" {
  name                = "pip-vm-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = merge(var.tags, {
    environment = var.environment
    module      = "compute"
    purpose     = "ssh-access"
  })
}

# Network Interface
resource "azurerm_network_interface" "main" {
  name                = "nic-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm.id
  }

  tags = merge(var.tags, {
    environment = var.environment
    module      = "compute"
  })
}

# Associate NIC with Load Balancer Backend Pool
resource "azurerm_network_interface_backend_address_pool_association" "main" {
  network_interface_id    = azurerm_network_interface.main.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = var.lb_backend_pool_id
}

# SSH Key
resource "azurerm_ssh_public_key" "main" {
  name                = "sshkey-${var.project_name}-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  public_key          = var.ssh_public_key

  tags = merge(var.tags, {
    environment = var.environment
  })
}

# Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "main" {
  name                = "vm-${var.project_name}-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = azurerm_ssh_public_key.main.public_key
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

  # Disable password authentication
  disable_password_authentication = true

  # Custom data for basic setup (Ansible will do the full installation)
  custom_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
    admin_username = var.admin_username
  }))

  tags = merge(var.tags, {
    environment = var.environment
    module      = "compute"
    role        = "gitea-server"
  })
}
