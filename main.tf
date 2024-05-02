resource "azurerm_storage_account" "sa01" {
  name                     = "sa01"
  resource_group_name      = azurerm_resource_group.rg01.name
  location                 = azurerm_resource_group.rg01.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

resource "azurerm_log_analytics_workspace" "log01" {
  name                = "log01"
  location            = azurerm_resource_group.rg01.location
  resource_group_name = azurerm_resource_group.rg01.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_sql_server" "sql01" {
  name                         = "sql01"
  resource_group_name          = azurerm_resource_group.rg01.name
  location                     = azurerm_resource_group.rg01.location
  version                      = "12.0"
  administrator_login          = "admin"
  administrator_login_password = "password"
}

resource "azurerm_linux_virtual_machine" "vm" {
  count                 = 3
  name                  = "VM${count.index + 1}"
  resource_group_name   = azurerm_resource_group.rg01.name
  location              = azurerm_resource_group.rg01.location
  size                  = "Standard_F2"
  admin_username        = "admin"
  disable_password_authentication = true

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  network_interface_ids = azurerm_network_interface.nic[count.index].id
}

resource "azurerm_network_interface" "nic" {
  count               = 3
  name                = "NIC${count.index + 1}"
  location            = azurerm_resource_group.rg01.location
  resource_group_name = azurerm_resource_group.rg01.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "static"
  }
}

resource "azurerm_bastion_host" "bastion" {
  name                = "BastionHost"
  location            = azurerm_resource_group.rg01.location
  resource_group_name = azurerm_resource_group.rg01.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg"
  location            = azurerm_resource_group.rg01.location
  resource_group_name = azurerm_resource_group.rg01.name

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
}

resource "azurerm_key_vault" "kv01" {
  name                        = "kv01"
  location                    = azurerm_resource_group.rg01.location
  resource_group_name         = azurerm_resource_group.rg01.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name = "standard"
}

resource "azurerm_key_vault_secret" "ssh01" {
  name         = "SSH01"
  value        = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbAunFb2xZ5MFU5k8bbAO8ihtjakV6B5nD6qvPkdJ6"
  key_vault_id = azurerm_key_vault.kv01.id
}
