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

variable "storage_account_sas_expiry" {
  type        = string
  description = "value"
}
variable "public_subscription_id" {
  type        = string
  description = "Subscription ID for Example-AZ-ExtProd"
  default     = "3d93b89d-8637-4fd0-910d-712f22aca770"
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

variable "application_cidrs" {
  description = "CIDRs for the application's VNet."
}

variable "access_tier" {
  type        = string
  description = "The storage access tier."
  default     = "Hot"
}

variable "account_kind" {
  type        = string
  description = "The storage account kind."
  default     = "StorageV2"
}

variable "account_replication_type" {
  type        = string
  description = "The account replication type for the storage account (LRS, GRZ, etc.)."
  default     = "RAGRS"
}

variable "account_tier" {
  type        = string
  description = "The storage account tier."
  default     = "Standard"
}
