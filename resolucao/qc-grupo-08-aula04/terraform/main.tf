terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

# RG e Function App já existem — criados pelo terraform da Aula 4
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_linux_function_app" "fn" {
  name                = var.function_app_name
  resource_group_name = var.resource_group_name
}
