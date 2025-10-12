variable "environment" {
  type        = string
  description = "The environment name for tags and resources."
}

variable "region" {
  type        = string
  description = "The region (pri or sec) that will host the app service plan."
}

variable "location" {
  type        = string
  description = "Location for the cluster."
}

variable "architecture" {
  type        = string
  description = "Architecture designator."
}

variable "app_name" {
  type        = string
  description = "A brief name for the app hosted in the app services."
}

variable "resource_group_name" {
  type        = string
  description = "An existing resource group that will contain the app services."
}

variable "app_settings" {
  type        = map(string)
  description = "The requested environment variables that will attach to the app services."
}

variable "app_services_subnet_id" {
  type        = string
  description = "The ID of a subnet to connect with the app service plan."
}

variable "shared_subnet_id" {
  type        = string
  description = "The ID of a shared subnet to connect with the app service plan. (non delegated) private endpoints will use this subnet."
}

variable "node_version" {
  type        = string
  description = "The version of node to install. Do not specify more than 1 programming language version."
  default     = null
}

variable "python_version" {
  type        = string
  description = "The version of python to install. Do not specify more than 1 programming language version."
  default     = null
}

variable "dotnet_version" {
  type        = string
  description = "The version of .NET to install. Do not specify more than 1 programming language version."
  default     = null
}

variable "https_only" {
  type        = bool
  description = "Only allow HTTPS traffic to the app services."
}

variable "public_network_access_enabled" {
  type        = bool
  description = "should the app services be accessible from the public internet."
}


variable "http2_enabled" {
  type        = bool
  description = "Should the app services use HTTP2"
}

variable "worker_count" {
  type        = number
  description = "The number of VMs hosting the app(s)."
}

variable "app_command_line" {
  type        = string
  default     = "mkdir -p logs | node ./src/server.js"
  description = "Command to start the node server."
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "ID of the log analytics workspace which will collect logs."
}