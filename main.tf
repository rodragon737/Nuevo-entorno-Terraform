terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }
  required_version = ">= 0.14.9"
}
provider "azurerm" {
  features {}
}
#Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "RG-${var.client_name}"
  location = "${var.this_location}"
}
#Network
#IP Public
resource "azurerm_public_ip" "rg" {
  name                = upper("IP-LB${var.client_name}-${var.enviroment}")
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  idle_timeout_in_minutes = "6"
  tags = {
    environment = "${var.enviroment}"
  }
}
#Virtual Network
resource "azurerm_virtual_network" "rg" {
  name                = "VNet-${var.client_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["${var.network}"]
  dns_servers         = ["${var.dns1}", "${var.dns2}"]
  tags = {
    environment = "${var.enviroment}"
  }
}
resource "azurerm_subnet" "rg" {
    name                          = upper("SN-${var.client_name}-${var.enviroment}")
    resource_group_name           = azurerm_resource_group.rg.name
    virtual_network_name          = azurerm_virtual_network.rg.name
    address_prefixes              = ["${var.subnet}"]
  }
#Load Balancer
resource "azurerm_lb" "rg" {
  name                = upper("LB-${var.client_name}-${var.enviroment}")
  sku                 = "Standard"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  frontend_ip_configuration {
    name                 = "LoadBalancerFrontEnd"
    public_ip_address_id = azurerm_public_ip.rg.id
  }
}
#Probe LB
resource "azurerm_lb_probe" "rg" {
  resource_group_name = azurerm_resource_group.rg.name
  loadbalancer_id     = azurerm_lb.rg.id
  for_each            = var.lb_probe
  name                = each.value.name
  protocol            = "Tcp"
  port                = each.value.port
  interval_in_seconds = 5
  number_of_probes    = 2
}
#Rule LB
resource "azurerm_lb_rule" "rg" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.rg.id
  name                           = "LB-HTTPS"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  idle_timeout_in_minutes        = 10
  enable_floating_ip             = false
  load_distribution              = "Default"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.rg.id
}
#Load Balancer outbound rule to NAT internet
resource "azurerm_lb_outbound_rule" "rg" {
  resource_group_name     = azurerm_resource_group.rg.name
  loadbalancer_id         = azurerm_lb.rg.id
  name                    = "LB-OUTBOUNDRULE"
  protocol                = "All"
  backend_address_pool_id = azurerm_lb_backend_address_pool.rg.id

  frontend_ip_configuration {
    name = "PublicIPAddress"
  }
}
# Backend
resource "azurerm_lb_backend_address_pool" "rg" {
  loadbalancer_id     = azurerm_lb.rg.id
  name                = "${var.client_name}Global"
}
resource "azurerm_network_interface" "rg" {
  name                           = lower("w19${var.client_name}_${var.enviroment}")
  location                       = azurerm_resource_group.rg.location
  resource_group_name            = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.rg.id
    private_ip_address            = "${var.win_privateip}"
    private_ip_address_allocation = "Dynamic"
  }
}
resource "azurerm_network_interface_backend_address_pool_association" "rg" {
  network_interface_id    = azurerm_network_interface.rg.id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.rg.id
}
#Private Link Service
resource "azurerm_private_link_service" "rg" {
  name                = upper("PRIVATE-LINK-${var.client_name}")
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  nat_ip_configuration {
    name      = azurerm_public_ip.rg.name
    primary   = true
    subnet_id = azurerm_subnet.rg.id
  }

  load_balancer_frontend_ip_configuration_ids = [
    azurerm_lb.rg.frontend_ip_configuration.0.id,
  ]
}
#Private Endpoint
resource "azurerm_private_endpoint" "rg" {
  resource_group_name  = azurerm_resource_group.rg.name
  name                 = "PL-${var.client_name}"
  subnet_id            = azurerm_subnet.rg.id
  location             = azurerm_resource_group.rg.location
  ##
  private_service_connection {
    name = upper("PSC${var.client_name}")
    private_connection_resource_id = azurerm_private_link_service.rg.id
    is_manual_connection = true
  }
}

#Virtual Machine
resource "azurerm_windows_virtual_machine" "rg" {
  name                  = upper("W19${var.client_name}L1")
  computer_name         = upper("W19${var.client_name}L1")
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = "Standard_B2ms"
  admin_username        = "${var.win_admin}"
  admin_password        = "${var.win_password}"
  network_interface_ids = [azurerm_network_interface.rg.id]
  os_disk {
    disk_size_gb         = 127
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

#Disk 
resource "azurerm_managed_disk" "rg" {
  name                 = lower("W19${var.client_name}L1_DataDisk_0")
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 64
}
resource "azurerm_virtual_machine_data_disk_attachment" "rg" {
  managed_disk_id    = azurerm_managed_disk.rg.id
  virtual_machine_id = azurerm_windows_virtual_machine.rg.id
  lun                = "0"
  caching            = "ReadWrite"
  # type               = "Microsoft.Compute/disks"
}
#Network Security Group
resource "azurerm_network_security_group" "rg" {
  name                 = "${azurerm_windows_virtual_machine.rg.name}-nsg"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowWebInBoundTraffic"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80,443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
  tags = {
    environment = "rrosales"
  }
}
#LOGIC APP
resource "azurerm_logic_app_workflow" "rg" {
  name                = "LA-${var.client_name}GetDistributorPriceLevel"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
#  workflow_schema     = "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#" 

}
resource "azurerm_logic_app_trigger_recurrence" "rg" {
  name         = "run-every-day"
  logic_app_id = azurerm_logic_app_workflow.rg.id
  frequency    = "Day"
  interval     = 1
  time_zone    = "UTC"
}
resource "azurerm_logic_app_action_http" "rg" {
  name           = "webhook"
  logic_app_id   = azurerm_logic_app_workflow.rg.id
  method         = "PUT"
  uri            = lower("https://api${var.client_name}.xssclients.com/api/v0.1/Distributor/PriceLevel")
}
#SQL Server
resource "azurerm_mssql_server" "rg" {
  name                         = "mssqlserver"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "${var.admin_sql_user}"
  administrator_login_password = "${var.admin_sql_pass}"
  minimum_tls_version          = "1.2"
}
#Data Base´s
resource "azurerm_mssql_database" "rg" {
  for_each              = var.databases
  name                  = "${var.client_name}_${each.value.name}"
  server_id             = azurerm_mssql_server.rg.id
  collation             = "SQL_Latin1_General_CP1_CI_AS"
  max_size_gb           = 270
  sku_name              = "S0"
  zone_redundant        = false
  storage_account_type  = "GRS"
  tags = {
    rrosales = "${var.client_name}"
  }
}
