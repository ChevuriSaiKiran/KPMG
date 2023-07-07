resource "azurerm_resource_group" "rg" {
  name     = "my-resource-group"
  location = "East US"
}

resource "azurerm_virtual_network" "my_vnet" {
  name                = "my-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "web_subnet" {
  name                 = "web-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.my_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "app_subnet" {
  name                 = "app-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.my_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "db_subnet" {
  name                 = "db-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.my_vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

resource "azurerm_public_ip" "lb_public_ip" {
  name                = "lb-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

resource "azurerm_lb" "my_lb" {
  name                = "my-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb_public_ip.id
  }
}

resource "azurerm_network_interface" "web_nic" {
  count               = 2
  name                = "web-nic-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "web-ipconfig"
    subnet_id                     = azurerm_subnet.web_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "app_nic" {
  count               = 2
  name                = "app-nic-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "app-ipconfig"
    subnet_id                     = azurerm_subnet.app_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "db_nic" {
  count               = 2
  name                = "db-nic-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "db-ipconfig"
    subnet_id                     = azurerm_subnet.db_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "web_vm" {
  count                       = 2
  name                        = "web-vm-${count.index}"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  network_interface_ids       = [azurerm_network_interface.web_nic[count.index].id]
  vm_size                     = "Standard_DS2_v2"
  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "web-osdisk-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "web-vm-${count.index}"
    admin_username = "adminuser"
    admin_password = "chevurisaikiran@123"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "azurerm_virtual_machine" "app_vm" {
  count                       = 2
  name                        = "app-vm-${count.index}"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  network_interface_ids       = [azurerm_network_interface.app_nic[count.index].id]
  vm_size                     = "Standard_DS2_v2"
  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "app-osdisk-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "app-vm-${count.index}"
    admin_username = "adminuser"
    admin_password = "chevurisaikiran@123"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "azurerm_virtual_machine" "db_vm" {
  count                       = 2
  name                        = "db-vm-${count.index}"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  network_interface_ids       = [azurerm_network_interface.db_nic[count.index].id]
  vm_size                     = "Standard_DS2_v2"
  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "MicrosoftSQLServer"
    offer     = "SQL2017-WS2016"
    sku       = "Web"
    version   = "latest"
  }

  storage_os_disk {
    name              = "db-osdisk-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "db-vm-${count.index}"
    admin_username = "adminuser"
    admin_password = "chevurisaikiran@123"
  }

    os_profile_linux_config {
    disable_password_authentication = true
  }
}

resource "azurerm_lb_backend_address_pool" "web_backend_pool" {
  name                = "web-backend-pool"
  loadbalancer_id     = azurerm_lb.my_lb.id
}

# Create load balancer backend pools for application servers
resource "azurerm_lb_backend_address_pool" "app_backend_pool" {
  name                = "app-backend-pool"
  loadbalancer_id     = azurerm_lb.my_lb.id
}

resource "azurerm_lb_backend_address_pool" "db_backend_pool" {
  name                = "db-backend-pool"
  loadbalancer_id     = azurerm_lb.my_lb.id
}

resource "azurerm_lb_probe" "web_probe" {
  name                = "web-probe"
  #resource_group_name = azurerm_resource_group.rg.name
  loadbalancer_id     = azurerm_lb.my_lb.id
  protocol            = "Tcp"
  port                = 80
  #interval            = 5
  #threshold           = 2
}

resource "azurerm_lb_probe" "app_probe" {
  name                = "app-probe"
  #resource_group_name = azurerm_resource_group.rg.name
  loadbalancer_id     = azurerm_lb.my_lb.id
  protocol            = "Tcp"
  port                = 8080
  #interval            = 5
  #threshold           = 2
}

resource "azurerm_lb_probe" "db_probe" {
  name                = "db-probe"
  #resource_group_name = azurerm_resource_group.rg.name
  loadbalancer_id     = azurerm_lb.my_lb.id
  protocol            = "Tcp"
  port                = 1433
  #interval            = 5
  #threshold           = 2
}

resource "azurerm_lb_rule" "web_rule" {
  name                           = "web-rule"
  #resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.my_lb.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.web_backend_pool.id]
  probe_id                       = azurerm_lb_probe.web_probe.id
}

resource "azurerm_lb_rule" "app_rule" {
  name                           = "app-rule"
  #resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.my_lb.id
  protocol                       = "Tcp"
  frontend_port                  = 8080
  backend_port                   = 8080
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.app_backend_pool.id]
  probe_id                       = azurerm_lb_probe.app_probe.id
}

resource "azurerm_lb_rule" "db_rule" {
  name                           = "db-rule"
  #resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.my_lb.id
  protocol                       = "Tcp"
  frontend_port                  = 1433
  backend_port                   = 1433
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids        = [azurerm_lb_backend_address_pool.db_backend_pool.id]
  probe_id                       = azurerm_lb_probe.db_probe.id
}
