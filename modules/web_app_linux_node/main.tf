terraform {
  required_version = ">=0.15"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.0"
    }
  }
}

locals {
  minimum_tls_version = "1.3"
  tags = {
    environment = var.environment
    region      = var.region
    location    = var.location
  }
}


resource "azurerm_service_plan" "plan" {
  name                = "asp-${var.environment}-${var.region}-${var.app_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "P1v2"
}

resource "azurerm_linux_web_app" "app" {
  name                = "app-${var.environment}-${var.region}-${var.app_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.plan.id
  site_config {
    always_on = true
    # api_definition_url = "" # for swagger, if it exists
    # api_management_api_id = ""
    app_command_line = var.app_command_line

    # Set the application stack with on of the following dynamic blocks.
    # Exactly 1 stack version needs to be specified when the module is called.
    dynamic "application_stack" {
      for_each = var.python_version != null ? [0] : []
      content {
        python_version = var.python_version
      }
    }

    dynamic "application_stack" {
      for_each = var.node_version != null ? [0] : []
      content {
        node_version = var.node_version
      }
    }

    dynamic "application_stack" {
      for_each = var.dotnet_version != null ? [0] : []
      content {
        dotnet_version = var.dotnet_version
      }
    }

    ftps_state = "Disabled"
    # health_check_path = ""
    # health_check_eviction_time_in_min = 2 # only valid with health_check_path
    http2_enabled = false
    # ip_restriction {}
    # ip_restriction_default_action = ""
    # load_balancing_mode = ""
    # managed_pipeline_mode = "Integrated" # default is Integrated, other option is Classic.
    minimum_tls_version      = local.minimum_tls_version
    remote_debugging_enabled = false
    # remote_debugging_version = "VS2022" # only use if remote_debugging_enabled = true; options: VS20{17,19,22}
    # scm_ip_restriction {}
    # scm_ip_restriction_default_action = ""
    # scm_minimum_tls_version = "1.2"
    # scm_use_main_ip_restriction = false
    # use_32_bit_worker = false # defaults to true
    vnet_route_all_enabled = false # defaults to false
    websockets_enabled     = false # defaults to false
    worker_count           = 1
  }

  # optional
  app_settings = var.app_settings

  # auth_settings {}
  # auth_settings_v2 {}
  # backup {
  #   name = "backup-${var.environment}-${var.region}-elastic-app"
  #   schedule {
  #     frequency_interval       = 1
  #     frequency_unit           = "Hour"
  #     keep_at_least_one_backup = true
  #     retention_period_days    = 30
  #     start_time               = timestamp()
  #   }
  #   storage_account_url = "${module.elastic_backup.primary_blob_endpoint}${local.backup_container_name}${module.elastic_backup_sas.sas_url}"
  # }
  client_affinity_enabled    = false
  client_certificate_enabled = false
  # client_certificate_mode = "Required (default) | Optional | OptionalInteractiveUser" # client certificate must be enabled
  # connection_string {}
  enabled = true
  # ftp_publish_basic_authentication_enabled = true # default is true
  https_only                    = var.https_only # default is false
  public_network_access_enabled = var.public_network_access_enabled # default is true
  identity {
    type = "SystemAssigned"
  }
  # key_vault_reference_identity_id = ""
  # logs {}
  # storage_account {}
  # sticky_settings {}
  virtual_network_subnet_id = var.app_services_subnet_id
  # webdeploy_publish_basic_authentication_enabled = true # default is true
  # zip_deploy_file = ""

  tags = {}

  lifecycle {
    ignore_changes = [
      app_settings,
      site_config[0].app_command_line,
      site_config[0].ftps_state,
      tags
    ]
  }
}

resource "azurerm_monitor_diagnostic_setting" "app" {
  name                       = "diag-${var.environment}-${var.region}-${var.app_name}-app"
  target_resource_id         = azurerm_linux_web_app.app.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # According to the JSON for an existing Web App, the following logs are available:
  # AppServiceAppLogs,AppServiceAuditLogs,AppServiceConsoleLogs,AppServiceHTTPLogs,
  # AppServiceIPSecAuditLogs,AppServicePlatformLogs,ScanLogs,AppServiceFileAuditLogs,
  # AppServiceAntivirusScanAuditLogs,AppServiceAuthenticationLogs
  enabled_log {
    category_group = "allLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_linux_web_app_slot" "stage" {
  name           = "app-${var.environment}-${var.region}-${var.app_name}-stage-slot"
  app_service_id = azurerm_linux_web_app.app.id
  https_only     = true
  site_config {
    always_on        = false
    app_command_line = var.app_command_line

    # Set the application stack with on of the following dynamic blocks.
    # Exactly 1 stack version needs to be specified when the module is called.
    dynamic "application_stack" {
      for_each = var.python_version != null ? [0] : []
      content {
        python_version = var.python_version
      }
    }

    dynamic "application_stack" {
      for_each = var.node_version != null ? [0] : []
      content {
        node_version = var.node_version
      }
    }

    dynamic "application_stack" {
      for_each = var.dotnet_version != null ? [0] : []
      content {
        dotnet_version = var.dotnet_version
      }
    }

    ftps_state               = "Disabled"
    http2_enabled            = var.http2_enabled
    minimum_tls_version      = local.minimum_tls_version
    remote_debugging_enabled = false
    vnet_route_all_enabled   = false # defaults to false
    websockets_enabled       = false # defaults to false
    worker_count             = var.worker_count
  }

  lifecycle {
    ignore_changes = [
      app_settings,
      site_config[0].app_command_line,
      tags
    ]
  }
}


output "app_id" {
  value = azurerm_linux_web_app.app.id
}