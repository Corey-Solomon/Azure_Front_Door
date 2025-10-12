variable "environment" {
  type        = string
  description = "The environment name for tags and resources."
}

variable "region" {
  type        = string
  description = "The region label (not location name) for tags and resources."
}

variable "location" {
  type        = string
  description = "Location for the cluster."
}

variable "app" {
  type        = string
  description = "The application name for the insights component."
}

variable "resource_group_name" {
  type        = string
  description = "The existing resource group to place the new resources into."
}

variable "scoped_service_name" {
  type        = string
  description = "Name for the azurerm_monitor_private_link_scoped_service block that links application insights to private link scope."
}

