terraform {
  required_version = ">=0.15"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.0"
    }
  }
}

provider "azurerm" {
  features {}
  alias           = "hub"
  subscription_id = var.hub_subscription_id
}

locals {
  front_door_profile_name                 = "afd-${var.environment}-example"
  front_door_endpoint_name                = "afd-ep-${var.environment}-example"
  front_door_origin_group_name            = "afdog-${var.environment}"
  front_door_origin_name                  = "afdo-${var.environment}"
  front_door_route_name                   = "afdr-${var.environment}"
  front_door_firewall_policy              = "afdfw${var.environment}example"
  front_door_custom_domain                = "afd-cd-${var.environment}-example"
  front_door_security_policy              = "afd-sp-${var.environment}-example"
  front_door_resource_group_name          = "rg-afd-${var.environment}-example"
  front_door_diagnostics_name             = "afd-diag-${var.environment}-example"
  dns_resource_group                      = "rg-${var.environment}-${var.region}-${var.architecture}-dns"
 
  tags = {
    environment = var.environment
    region      = var.region
    location    = var.location
  }
}

data "azurerm_log_analytics_workspace" "log" {

  provider            = azurerm.hub
  name                = "log-inthub-eastus"
  resource_group_name = "rg-inthub-eastus-arch1-log"
}

resource "azurerm_resource_group" "afd" {
  name     = local.front_door_resource_group_name
  location = var.location
  tags     = local.tags
}  

resource "azurerm_cdn_frontdoor_profile" "afd" {
  name                = local.front_door_profile_name
  resource_group_name = local.front_door_resource_group_name
  sku_name            = "Premium_AzureFrontDoor"

  depends_on = [
    azurerm_resource_group.afd
  ]
}

resource "azurerm_cdn_frontdoor_endpoint" "afd_ep" {
  name                     = local.front_door_endpoint_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.afd.id
  enabled                  = true
}

resource "azurerm_cdn_frontdoor_origin_group" "afd_og_example" {
  name                     = "${local.front_door_origin_group_name}-app-example"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.afd.id

  load_balancing {
    additional_latency_in_milliseconds = 50
    sample_size                        = 4
    successful_samples_required        = 3
  }

  health_probe {
    interval_in_seconds = 100
    path                = "/"
    protocol            = "Https"
    request_type        = "HEAD"
  }
}

resource "azurerm_monitor_diagnostic_setting" "fd_diagnostic" {
  name                       = "${local.front_door_diagnostics_name}"
  target_resource_id         = azurerm_cdn_frontdoor_profile.afd.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.log.id

  enabled_log {
    category = "FrontdoorAccessLog"
    retention_policy {
      enabled = false
      days    = 0
    }
  }

  enabled_log {
    category = "FrontdoorWebApplicationFirewallLog"
    retention_policy {
      enabled = false
      days    = 0
    }
  }

  
  enabled_log {
    category = "FrontdoorhealthProbeLog"
    retention_policy {
      enabled = false
      days    = 0
    }
  }

  metric {
    category = "AllMetrics"
    retention_policy {
      enabled = false
      days    = 0
    }
  }
}

resource "azurerm_cdn_frontdoor_firewall_policy" "afd_waf_policy" {
  name                = local.front_door_firewall_policy
  resource_group_name = local.front_door_resource_group_name
  sku_name            = "Premium_AzureFrontDoor"

  enabled                           = true
  mode                              = "Prevention" # "Detection" for monitor-only mode
  tags                              = {}
  custom_block_response_status_code = 403
  request_body_check_enabled        = true

  # Default Microsoft rules
  managed_rule {
    type    = "Microsoft_DefaultRuleSet"
    version = "2.1"
    action  = "Block"
  }

  # Bot manager rules
  managed_rule {
    type    = "Microsoft_BotManagerRuleSet"
    version = "1.1"
    action  = "Block"  # can be overridden if needed
  }

  depends_on = [
    azurerm_resource_group.afd
  ]
}

resource "azurerm_cdn_frontdoor_security_policy" "afd_security_policy" {
    name                            = local.front_door_security_policy
    cdn_frontdoor_profile_id        = azurerm_cdn_frontdoor_profile.afd.id

    security_policies {
      firewall {
        cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.afd_waf_policy.id
        
      association {
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.afd_ep.id
        }
        patterns_to_match = ["/*"]
      }
    }
  }
}