# The resource group is created by an admin; the pipeline only manages what's inside it.
data "azurerm_resource_group" "lab" {
  name = var.resource_group_name
}

locals {
  tags = {
    project    = "gh600"
    managed_by = "terraform"
    repo       = "tf-agent-lab"
  }
  # Storage account names must be globally unique: add a short, stable suffix.
  storage_name = "st${var.name_prefix}${substr(md5(data.azurerm_resource_group.lab.id), 0, 6)}"
}

resource "azurerm_virtual_network" "lab" {
  name                = "vnet-${var.name_prefix}"
  location            = data.azurerm_resource_group.lab.location
  resource_group_name = data.azurerm_resource_group.lab.name
  address_space       = ["10.60.0.0/16"]
  tags                = local.tags
}

resource "azurerm_subnet" "app" {
  name                 = "snet-app"
  resource_group_name  = data.azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.lab.name
  address_prefixes     = ["10.60.1.0/24"]
}

resource "azurerm_storage_account" "app" {
  name                     = local.storage_name
  resource_group_name      = data.azurerm_resource_group.lab.name
  location                 = data.azurerm_resource_group.lab.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Secure defaults: HTTPS only, modern TLS, no anonymous blob access.
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false # Entra ID only: no storage keys to leak

  # Deny traffic from all networks by default (only trusted Azure services get through).
  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  tags = local.tags

  # Storage holds data: make Terraform refuse to destroy it by accident.
  lifecycle {
    prevent_destroy = true
  }
}
