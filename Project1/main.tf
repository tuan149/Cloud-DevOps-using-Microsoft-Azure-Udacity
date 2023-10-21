provider "azurerm" {
  features {}
}

resource "azurerm_availability_set" "main" {
  name                = "${var.prefix}-aset"
  location            = var.location
  resource_group_name = var.resourceGroup

  tags = {
    Owner = "TuanTM22"
  }
}

# 1 Create Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/22"]
  location            = var.location
  resource_group_name = var.resourceGroup

  tags = {
    Owner = "TuanTM22"
  }
}

# 2 Create Subet
resource "azurerm_subnet" "main" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = var.resourceGroup
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

# 3 Create Network Security, Security Group, Security Rule
resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-security-group"
  location            = var.location
  resource_group_name = var.resourceGroup

  security_rule {
    name                       = "${var.prefix}-allow-outbound-subnet"
    priority                   = 1000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "${var.prefix}-allow-inbound-subnet"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "${var.prefix}-deny-inbound-internet"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Owner = "TuanTM22"
  }
}

# 4 Create Network Interface
resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-network_interface-${count.index}"
  resource_group_name = var.resourceGroup
  location            = var.location
  count               = var.vmCount

  ip_configuration {
    name                          = "main"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    Owner = "TuanTM22"
  }
}

# 5 Create Public IP
resource "azurerm_public_ip" "main" {
  name                = "${var.prefix}-public-ip"
  location            = var.location
  resource_group_name = var.resourceGroup
  allocation_method   = "Static"

  tags = {
    Owner = "TuanTM22"
  }
}

# 6 Create Load Balancer
resource "azurerm_lb" "main" {
  name                = "${var.prefix}-load-balancer"
  location            = var.location
  resource_group_name = var.resourceGroup

  frontend_ip_configuration {
    name                 = "${var.prefix}-frontend-ip"
    public_ip_address_id = azurerm_public_ip.main.id
  }

  tags = {
    Owner = "TuanTM22"
  }
}

# 7 Create Load Balancer Rules
resource "azurerm_lb_rule" "main" {
  loadbalancer_id                = azurerm_lb.main.id
  name                           = "${var.prefix}-load-balancer-rule"
  protocol                       = "Tcp"
  frontend_port                  = 8080
  backend_port                   = 80
  frontend_ip_configuration_name = "${var.prefix}-frontend-ip"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main.id]

  depends_on = [
    azurerm_lb.main
  ]
}

# 8 Create Backend Adress Pool 
resource "azurerm_lb_backend_address_pool" "main" {
  loadbalancer_id = azurerm_lb.main.id
  name            = "${var.prefix}-backend-address-pool"
}

resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = azurerm_subnet.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

resource "azurerm_network_interface_backend_address_pool_association" "main" {
  count                   = var.vmCount
  network_interface_id    = element(azurerm_network_interface.main.*.id, count.index)
  ip_configuration_name   = "main"
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
}

resource "azurerm_linux_virtual_machine" "main" {
  count                           = var.vmCount
  name                            = "${var.prefix}-vm-${count.index}"
  resource_group_name             = var.resourceGroup
  location                        = var.location
  size                            = "Standard_D2s_v3"
  admin_username                  = "${var.username}"
  admin_password                  = "${var.password}"
  disable_password_authentication = false
  network_interface_ids           = [element(azurerm_network_interface.main.*.id, count.index)]
  
  availability_set_id = azurerm_availability_set.main.id
  source_image_id     = var.packerImageId

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  tags = {
    Owner = "TuanTM22"
  }
}