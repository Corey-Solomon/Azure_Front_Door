terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = "~>4.0"
      configuration_aliases = [azurerm.app, azurerm.hub]
    }
  }
}

module "variables" {
  source = "../variables"
}

locals {
  component_name          = "appi-${var.environment}-${var.region}-${var.app}"
  log_resource_group      = "rg-inthub-eastus-arch1-log"
  log_workspace_name      = "log-inthub-eastus"
  diagnostic_setting_name = "diag-${var.environment}-${var.region}-appi-${var.app}"
  private_link_scope_name = "ampls-${var.region}"

  tags = {
    environment = var.environment
    region      = var.region
    location    = var.location
  }
}

data "azurerm_log_analytics_workspace" "logs" {
  provider            = azurerm.hub
  name                = local.log_workspace_name
  resource_group_name = local.log_resource_group
}

resource "azurerm_application_insights" "insights" {
  provider            = azurerm.app
  name                = local.component_name
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = data.azurerm_log_analytics_workspace.logs.id
  application_type    = "web"
  # need to enable this for now
  internet_ingestion_enabled = true
  internet_query_enabled     = true
  tags                       = local.tags

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

# link application insights to AMPLS
resource "azurerm_monitor_private_link_scoped_service" "appi" {
  provider = azurerm.hub
  
  name                = var.scoped_service_name
  resource_group_name = local.log_resource_group
  scope_name          = local.private_link_scope_name
  linked_resource_id  = azurerm_application_insights.insights.id
}

resource "azurerm_monitor_diagnostic_setting" "insights" {
  name                       = local.diagnostic_setting_name
  target_resource_id         = azurerm_application_insights.insights.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.logs.id
  # The following setting always comes up in terraform plans as needing to change.
  # I'm guessing that Azure now considers this to be the norm so it probably isn't required.
  # But the Hashicorp docs don't corroborate that, at least not yet.
  # log_analytics_destination_type = "Dedicated"

  # Microsoft reference for log names:
  # https://learn.microsoft.com/en-us/azure/azure-monitor/monitor-azure-monitor-reference#supported-resource-logs-for-microsoftinsightscomponents
  enabled_log {
    category = "AppAvailabilityResults"
  }

  # enabled_log {
  #   category = "AppBrowserTimings"
  # }

  enabled_log {
    category = "AppDependencies"
  }

  enabled_log {
    category = "AppEvents"
  }

  enabled_log {
    category = "AppExceptions"
  }

  enabled_log {
    category = "AppMetrics"
  }

  # enabled_log {
  #   category = "AppPageViews"
  # }

  # enabled_log {
  #   category = "AppPerformanceCounters"
  # }

  # enabled_log {
  #   category = "AppRequests"
  # }

  enabled_log {
    category = "AppSystemEvents"
  }

  enabled_log {
    category = "AppTraces"
  }

  enabled_metric {
    category = "AllMetrics"
  }

  depends_on = [
    azurerm_application_insights.insights
  ]
}

output "instrumentation_key" {
  value     = azurerm_application_insights.insights.instrumentation_key
  sensitive = true
}

output "app_id" {
  value = azurerm_application_insights.insights.app_id
}

output "id" {
  value = azurerm_application_insights.insights.id
}

output "connection_string" {
  value     = azurerm_application_insights.insights.connection_string
  sensitive = true
}
