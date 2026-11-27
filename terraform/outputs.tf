output "storage_account_name" {
  value = azurerm_storage_account.app.name
}

output "vnet_id" {
  value = azurerm_virtual_network.lab.id
}
