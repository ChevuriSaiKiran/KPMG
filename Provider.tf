terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = "98ee4969-34f5-4d10-989b-eaf1b0a82b7c"
  client_id = "834f6550-69c5-41eb-9875-5b1b060c7e49"
  client_secret = "Tx48Q~yNasVUJyFYcJKlcXZTw_VhXcSDXXEbLds4"
  tenant_id = "24d27e4f-e0ae-473e-8c75-642629fd4689"
}
