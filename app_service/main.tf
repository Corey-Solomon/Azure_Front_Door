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
    storage_account_name = "<STORAGE ACCOUNT NAME>"
    container_name       = "arch1"
    key                  = ""
    subscription_id      = "<SUBSCRIPTION ID"
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

provider "azuredevops" {
  org_service_url = "https://dev.azure.com/<INSERT_ORGANIZATION_HERE>/"
  # Note: if using a PAT, store it in the env var, AZDO_PERSONAL_ACCESS_TOKEN
}

locals {
  app                             = "example_appsvc"
  exappsvc_resource_group        = "rg-${var.environment}-${var.region}-${var.architecture}-${local.app}"
  dns_resource_group              = "rg-${var.environment}-${var.region}-${var.architecture}-dns"
  peer_from_exappsvc_to_hub      = "peer-${var.environment}-${var.region}-exappsvc-to-hub"
  peer_from_hub_to_exappsvc      = "peer-${var.environment}-${var.region}-hub-to-exappsvc"
  front_door_profile_name         = "afd-${var.environment}-example"
  front_door_endpoint_name        = "afd-ep-${var.environment}-example"
  front_door_origin_group_name    = "afdog-${var.environment}"
  front_door_origin_name          = "afdo-${var.environment}"
  front_door_route_name           = "afdr-${var.environment}"
  private_endpoint_name           = "pend-${var.environment}-${var.region}-exappsvc"
  private_service_connection_name = "psc-${var.environment}-${var.region}-exappsvc"
  
}

data "azurerm_virtual_network" "hub" {
  resource_group_name = "rg-${var.environment}-${var.region}-${var.architecture}-net"
  name                = "vnet-${var.environment}-${var.region}-hub"
} 

data "azurerm_cdn_frontdoor_profile" "afd" {
  name                = local.front_door_profile_name
  resource_group_name = "rg-afd-${var.environment}-example"
}

data "azurerm_cdn_frontdoor_endpoint" "afd_ep" {
  name                = local.front_door_endpoint_name
  profile_name        = local.front_door_profile_name
  resource_group_name = "rg-afd-${var.environment}-example"
}

data "azurerm_cdn_frontdoor_origin_group" "afd_og_exappsvc" {
  name                = "${local.front_door_origin_group_name}-exappsvc-example"
  profile_name        = local.front_door_profile_name
  resource_group_name = "rg-afd-${var.environment}-example"
}

data "azurerm_private_dns_zone" "exappsvc_default" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = local.dns_resource_group
}


data "azurerm_log_analytics_workspace" "log" {
  provider            = azurerm.hub
  name                = "log-inthub-eastus"
  resource_group_name = "rg-inthub-eastus-arch1-log"
}

resource "azurerm_virtual_network_peering" "hub_to_exappsvc" {
  name                         = local.peer_from_hub_to_exappsvc
  resource_group_name          = data.azurerm_virtual_network.hub.resource_group_name
  virtual_network_name         = data.azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.exappsvc.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
  use_remote_gateways          = false

  depends_on = [ azurerm_virtual_network.exappsvc ]
  }

 resource "azurerm_virtual_network_peering" "exappsvc_to_hub" {
   name                         = local.peer_from_exappsvcy_to_hub
   resource_group_name          = azurerm_resource_group.exappsvc.name   
   virtual_network_name         = azurerm_virtual_network.exappsvc.name
   remote_virtual_network_id    = data.azurerm_virtual_network.hub.id
   allow_virtual_network_access = true
   allow_forwarded_traffic      = false
   allow_gateway_transit        = false
   use_remote_gateways          = false

   depends_on = [ azurerm_virtual_network.exappsvc ]
 }


resource "azurerm_resource_group" "exappsvc" {
  name     = local.exappsvc_resource_group
  location = var.location
}

resource "azurerm_virtual_network" "exappsvc" {
  name                = "vnet-${var.environment}-${var.region}-exappsvc"
  resource_group_name = local.exappsvc_resource_group
  location            = var.location
  address_space       = [var.application_cidrs["everything"]]

  depends_on = [azurerm_resource_group.exappsvc]
}

resource "azurerm_subnet" "exappsvc" {
  name                 = "subnet-${var.environment}-${var.region}-exappsvc"
  resource_group_name  = local.exappsvc_resource_group
  virtual_network_name = azurerm_virtual_network.exappsvc.name
  address_prefixes     = [var.application_cidrs["appservice"]]

  delegation {
    name = "delegate-to-app-services"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action",
      ]
    }
  }
}

resource "azurerm_subnet" "shared" {
  name                 = "subnet-${var.environment}-${var.region}-shared"
  resource_group_name  = local.exappsvc_resource_group
  virtual_network_name = azurerm_virtual_network.exappsvc.name
  address_prefixes     = [var.application_cidrs["shared"]]
}

resource "azurerm_private_dns_zone_virtual_network_link" "exappsvc_default" {
  virtual_network_id    = azurerm_virtual_network.exappsvc.id
  resource_group_name   = local.dns_resource_group
  name                  = "vnl-${var.environment}-${var.region}-exappsvc-default"
  private_dns_zone_name = "privatelink.azurewebsites.net"
}

module "insights" {
  providers = {
    azurerm.app = azurerm
    azurerm.hub = azurerm.hub
  }
  source              = "../modules/insights"
  region              = var.region
  environment         = var.environment
  location            = var.location
  app                 = "exappsvc"
  resource_group_name = azurerm_resource_group.exappsvc.name
  scoped_service_name = "amplsservice-appi-${var.region}-exappsvc"
}

module "linux_web_app" {
  source                           = "../modules/web_app_linux_node"
  region                           = var.region
  environment                      = var.environment
  location                         = var.location
  architecture                     = var.architecture
  app_name                         = "exappsvc"
  resource_group_name              = azurerm_resource_group.exappsvc.name
  app_services_subnet_id           = azurerm_subnet.exappsvc.id
  shared_subnet_id                 = azurerm_subnet.shared.id
  https_only                       = false
  public_network_access_enabled    = false
  http2_enabled                    = true
  log_analytics_workspace_id       = data.azurerm_log_analytics_workspace.log.id
  worker_count                     = 1
  app_command_line                 = ""
  app_settings                     = {

    "APPINSIGHTS_APPLICATION_ID"                 = module.insights.app_id,
    "APPINSIGHTS_INSTRUMENTATIONKEY"             = module.insights.instrumentation_key,
    "APPLICATIONINSIGHTS_CONNECTION_STRING"      = module.insights.connection_string,
    "ApplicationInsightsAgent_EXTENSION_VERSION" = "~3",
    "WEBSITE_ENABLE_SYNC_UPDATE_SITE"            = "true",
    "XDT_MicrosoftApplicationInsights_Mode"      = "default"
  }

  depends_on = [
    module.insights
  ]
}

# Creates a Private Endpoint inside your private subnet. Wires app service default hostname to a private IP inside the private zone.
resource "azurerm_private_endpoint" "exappsvc_pe" {
  name                = local.private_endpoint_name
  location            = var.location
  resource_group_name = local.exappsvc_resource_group
  subnet_id           = azurerm_subnet.shared.id

  private_service_connection {
    name                           = local.private_service_connection_name
    private_connection_resource_id = module.linux_web_app.app_id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  depends_on = [azurerm_resource_group.exappsvc]
}

resource "azurerm_private_dns_a_record" "exappsvc_default" {
  name                = "app-pub-pri-exappsvc" # the hostname prefix of your default domain
  zone_name           = data.azurerm_private_dns_zone.exappsvc_default.name
  resource_group_name = local.dns_resource_group
  ttl                 = 300
  records             = [azurerm_private_endpoint.exappsvc_pe.private_service_connection[0].private_ip_address]

  depends_on = [azurerm_resource_group.exappsvc]
}


resource "azurerm_cdn_frontdoor_origin" "afd_origin_exappsvc" {
  name                           = "${local.front_door_origin_name}-exappsvc-example"
  cdn_frontdoor_origin_group_id  = data.azurerm_cdn_frontdoor_origin_group.afd_og_exappsvc.id
  host_name                      = "app-pub-pri-exappsvc.azurewebsites.net"
  origin_host_header             = "app-pub-pri-exappsvc.azurewebsites.net"
  http_port                      = 80
  https_port                     = 443
  priority                       = 1
  weight                         = 1000
  enabled                        = true
  certificate_name_check_enabled = true

# links to app service to enable private link connection between front door and app service / Must be manually approved in Azure Portal
private_link {
    request_message        = "Front Door to App Service over Private Link"
    target_type            = "sites" # App Service
    location               = var.location
    private_link_target_id = module.linux_web_app.app_id
  }

  depends_on = [azurerm_resource_group.exappsvc]
}

resource "azurerm_cdn_frontdoor_route" "afd_route_exappsvc" {
  name                          = "${local.front_door_route_name}-exappsvc-example"
  cdn_frontdoor_endpoint_id     = data.azurerm_cdn_frontdoor_endpoint.afd_ep.id
  cdn_frontdoor_origin_group_id = data.azurerm_cdn_frontdoor_origin_group.afd_og_exappsvc.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.afd_origin_exappsvc.id]

  supported_protocols    = ["Http", "Https"   ]
  patterns_to_match      = ["/*"]
  forwarding_protocol    = "MatchRequest"
  https_redirect_enabled = true
  link_to_default_domain = true
  enabled                = true

  cache {
    query_string_caching_behavior = "IgnoreQueryString"
    compression_enabled           = false
  }

  depends_on = [azurerm_resource_group.exappsvc]
}