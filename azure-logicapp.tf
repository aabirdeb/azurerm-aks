resource "azurerm_app_service_plan" "this" {
  for_each            = var.logic_app
  name                = format("%s-%s", local.app_service_plan, each.key)
  location            = var.location
  resource_group_name = var.resource_group_name


  sku {
    tier = lookup(each.value, "tier")
    size = lookup(each.value, "size")
  }
  #tags = local.sa_tags

}
resource "azurerm_logic_app_standard" "this" {
  for_each                   = var.logic_app
  name                       = format("%s-%s", local.logicapp_name, each.key)
  location                   = var.location
  resource_group_name        = var.resource_group_name
  app_service_plan_id        = azurerm_app_service_plan.this[each.key].id
  storage_account_name      = lookup(each.value, "storage_name")
 #In this configuration, the azurerm_storage_account resource creates a storage account named "mystorageaccount" in the resource group created in the azurerm_resource_group resource block. The account_tier and account_replication_type parameters specify the performance and redundancy options for the storage account, respectively. The network_rules block specifies that all network access to the storage account should be denied by default. The blob_properties block sets the delete retention policy to disabled and enables versioning for the blobs in the storage account. Finally, the lifecycle block prevents the storage
    
  storage_account_access_key = lookup(each.value, "storage_primary_access_key")
}
resource "azurerm_app_service_virtual_network_swift_connection" "this" {
  for_each       = var.logic_app
  app_service_id = azurerm_logic_app_standard.this[each.key].id
  subnet_id      = lookup(each.value, "swift_connection_subnet_id")
}


resource "azurerm_private_endpoint" "this" {
  for_each            = var.isprivateendpointrequired ? var.logic_app : {}
  name                = format("%s-%s", azurerm_logic_app_standard.this[each.key].name, "pep")
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = lookup(each.value, "subnet_id")

  private_service_connection {
    is_manual_connection           = false
    name                           = azurerm_logic_app_standard.this[each.key].name
    private_connection_resource_id = azurerm_logic_app_standard.this[each.key].id
    subresource_names              = ["sites"]
  }
}
