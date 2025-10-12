variable "environment" {
  type        = string
  description = "The environment name for tags and resources."
}

variable "architecture" {
  type        = string
  description = "Architecture designator."
}

variable "region" {
  type        = string
  description = "Region that will contain the resource (pri, sec, ...)."
}

variable "location" {
  type        = string
  default     = "eastus"
  description = "Location for the cluster."
}

variable "hub_subscription_id" {
  type        = string
  description = "Subscription ID for Example-AZ-Hub"
}