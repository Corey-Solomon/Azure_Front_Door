variable "location" {
  type        = string
  description = "The location for resources."
}

variable "region" {
  type        = string
  description = "The region (pri, sec, ...) for resources."
}

variable "environment" {
  type        = string
  description = "The environment (pub or hub) for the resources."
}

variable "architecture" {
  type        = string
  description = "Architecture designator (arch1, etc.)"
}

variable "public_subscription_id" {
  type        = string
  description = "Subscription ID for Example-AZ-ExtProd"
  default     = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
}

variable "hub_subscription_id" {
  type        = string
  description = "Subscription ID for Example-AZ-Hub"
  default     = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
}

variable "tenant_id" {
  type        = string
  description = "Entra tenant ID."
  default     = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
}