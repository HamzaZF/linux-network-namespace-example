terraform {
  required_version = ">= 1.12.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.57"
    }

    http = {
      source = "hashicorp/http"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}