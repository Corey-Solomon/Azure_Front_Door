terraform {
  required_version = ">=0.15"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.0"
    }

    azuredevops = {
      source  = "microsoft/azuredevops"
      version = ">= 0.1.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-inthub-pri-tfstate"
    storage_account_name = "tfstateinthubpristorage"
    container_name       = "arch1"
    key                  = ""
    subscription_id      = "<subscription ID>"
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.public_subscription_id
}

provider "azurerm" {
  features {}
  alias           = "hub"
  subscription_id = var.hub_subscription_id
}

locals {
  front_door_profile_name      = "afd-${var.environment}-example"
  front_door_endpoint_name     = "afd-ep-${var.environment}-example"
  front_door_origin_group_name = "afdog-${var.environment}-example"
  front_door_origin_name       = "afdo-${var.environment}-example"
  front_door_route_name        = "afdr-${var.environment}-example"
  resource_group               = "rg-afd-${var.environment}-example"
  tags = {
    environment = var.environment
    region      = var.region
    location    = var.location
  }
}

module "front_door" {
  source                           = "../modules/front_door"
  region                           = var.region
  environment                      = var.environment
  location                         = var.location
  architecture                     = var.architecture
  hub_subscription_id              = var.hub_subscription_id
}