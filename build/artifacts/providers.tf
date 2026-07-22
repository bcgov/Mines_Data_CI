terraform {
  backend "local" {
    # __ENV__ is replaced with dev/test/prod by the CI/CD workflows so each
    # environment branch keeps its own state file and can never read another
    # environment's state.
    path = "terraform-__ENV__.tfstate"
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.49.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "2.0.1"
    }
    fabric = {
      source  = "microsoft/fabric"
      version = "1.10.0"
    }
  }
}


provider "azurerm" {
  resource_provider_registrations = "none"
  use_cli                         = false
  subscription_id                 = var.ARM_SUBSCRIPTION_ID
  tenant_id                       = var.ARM_TENANT_ID
  client_id                       = var.ARM_CLIENT_ID
  client_secret                   = var.ARM_CLIENT_SECRET
  features {}
}

provider "azapi" {
  subscription_id = var.ARM_SUBSCRIPTION_ID
  tenant_id       = var.ARM_TENANT_ID
  client_id       = var.ARM_CLIENT_ID
  client_secret   = var.ARM_CLIENT_SECRET
}

provider "fabric" {
  alias         = "auth"
  tenant_id     = var.ARM_TENANT_ID
  client_id     = var.ARM_CLIENT_ID
  client_secret = var.ARM_CLIENT_SECRET
  preview       = true
}
