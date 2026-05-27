terraform {
  backend "local" {
    path = "terraform.tfstate"
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.49"
    }

    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }

    fabric = {
      source  = "microsoft/fabric"     # ← Must be this
      version = "~> 1.10"
    }
  }
}

# AzureRM
provider "azurerm" {
  resource_provider_registrations = "none"
  use_cli                         = false
  subscription_id = var.ARM_SUBSCRIPTION_ID
  tenant_id       = var.ARM_TENANT_ID
  client_id       = var.ARM_CLIENT_ID
  client_secret   = var.ARM_CLIENT_SECRET
  features {}
}

# AzAPI
provider "azapi" {
  subscription_id = var.ARM_SUBSCRIPTION_ID
  tenant_id       = var.ARM_TENANT_ID
  client_id       = var.ARM_CLIENT_ID
  client_secret   = var.ARM_CLIENT_SECRET
}

# Fabric - Aliased (recommended for modules)
provider "fabric" {
  alias = "auth"

  tenant_id     = var.ARM_TENANT_ID
  client_id     = var.ARM_CLIENT_ID
  client_secret = var.ARM_CLIENT_SECRET
  preview       = true
}

# Fabric - Default
provider "fabric" {
  tenant_id     = var.ARM_TENANT_ID
  client_id     = var.ARM_CLIENT_ID
  client_secret = var.ARM_CLIENT_SECRET
  preview       = true
}