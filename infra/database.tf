
# ====================================
# Compute - Linux VM for MySQL
# ====================================

# Note: MySQL VM does not have a public IP
# Access is via SSH jump host through Gitea VM for security and quota optimization

resource "azurerm_network_interface" "mysql" {
	name                = "nic-mysql-${var.project_name}-${var.environment}"
	location            = var.location
	resource_group_name = azurerm_resource_group.main.name

	ip_configuration {
		name                          = "internal"
		subnet_id                     = azurerm_subnet.database.id
		private_ip_address_allocation = "Dynamic"
		# No public IP - access via jump host through Gitea VM
	}

	tags = merge(var.tags, {
		environment = var.environment
		component   = "database"
	})
}

resource "azurerm_linux_virtual_machine" "mysql" {
	name                = "vm-mysql-${var.project_name}-${var.environment}"
	resource_group_name = azurerm_resource_group.main.name
	location            = var.location
	size                = var.vm_size
	admin_username      = var.vm_admin_username

	network_interface_ids = [
		azurerm_network_interface.mysql.id,
	]

	admin_ssh_key {
		username   = var.vm_admin_username
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

	disable_password_authentication = true

	tags = merge(var.tags, {
		environment = var.environment
		component   = "database"
		role        = "mysql-server"
	})
}

