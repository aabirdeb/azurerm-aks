terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      
    }
  }
}
provider "azurerm" {
  features {}
}

module "logic_app" {
  source = "/home/bapi/Desktop/log/Modules/logic_app"

  # Required variables
  client_name          = "myclient"
  environment          = "dev"
  resource_group_name  = "myresourcegroup"
  location             = "eastus"
  
  # Optional variables
  name                 = "mylogicapp"
  role                 = "myrole"
  tags = {
    "owner" = "myteam"
    "cost_center" = "12345"
  }

  # Logic App specific variables
  logic_app = {
    "app1" = {
      "tier"                  = "Standard"
      "size"                  = "S1"
      "storage_name"          = "mystorageaccount1"
      "storage_primary_access_key" = "myaccesskey1"
      "swift_connection_subnet_id" = "/subscriptions/12345678-1234-1234-1234-1234567890ab/resourceGroups/myresourcegroup/providers/Microsoft.Network/virtualNetworks/myvnet/subnets/mysubnet"
      "subnet_id"             = "/subscriptions/12345678-1234-1234-1234-1234567890ab/resourceGroups/myresourcegroup/providers/Microsoft.Network/virtualNetworks/myvnet/subnets/mysubnet"
    },
    "app2" = {
      "tier"                  = "Basic"
      "size"                  = "B1"
      "storage_name"          = "mystorageaccount2"
      "storage_primary_access_key" = "myaccesskey2"
      "swift_connection_subnet_id" = "/subscriptions/12345678-1234-1234-1234-1234567890ab/resourceGroups/myresourcegroup/providers/Microsoft.Network/virtualNetworks/myvnet/subnets/mysubnet"
      "subnet_id"             = "/subscriptions/12345678-1234-1234-1234-1234567890ab/resourceGroups/myresourcegroup/providers/Microsoft.Network/virtualNetworks/myvnet/subnets/mysubnet"
    }
  }
}

  
  #NOUPDATES REQUIRED 
