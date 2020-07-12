terraform {
  required_version = "= 0.12.20"
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

data "null_data_source" "common_tags" {
  inputs = {
    subscription_owner = var.subscription_owner
    infrastructure     = var.resource_group_name
  }
}

# -----------------------------------------------------------------------------
# Fetching module patterns with a specific sematic version
# -----------------------------------------------------------------------------

module "landing-zone-1-0-0" {
  source = "github.com/bryan-nice/terraform-azure-modules?ref=1.1.0"
}

# -----------------------------------------------------------------------------
# Landing Zone Resource Group
# -----------------------------------------------------------------------------

module "landing_zone_resource_group" {
  source   = "./.terraform/modules/landing-zone-1-0-0/resource-group"
  name     = var.resource_group_name
  location = var.location
  tags = merge(
    data.null_data_source.common_tags.outputs,
    map(
      "resource_type", "resource group"
    )
  )
}

# -----------------------------------------------------------------------------
# Landing Zone Log Analytics Workspace
# -----------------------------------------------------------------------------

module "landing_zone_log_analytics_workspace" {
  source              = "./.terraform/modules/landing-zone-1-0-0/log-analytics/workspace"
  name                = var.resource_group_name
  resource_group_name = module.landing_zone_resource_group.name
  location            = module.landing_zone_resource_group.location
  sku                 = "Standard"

  tags = merge(
    data.null_data_source.common_tags.outputs,
    map(
      "resource_type", "log analytics workspace"
    )
  )
}

# -----------------------------------------------------------------------------
# Landing Zone Log Analytics Solutions
# -----------------------------------------------------------------------------

module "landing_zone_log_analytics_solutions" {
  source                = "./.terraform/modules/landing-zone-1-0-0/log-analytics/solution"
  workspace_name        = module.landing_zone_log_analytics_workspace.name
  workspace_resource_id = module.landing_zone_log_analytics_workspace.id
  resource_group_name   = module.landing_zone_resource_group.name
  location              = module.landing_zone_resource_group.location
  products = [
    "OMSGallery/NetworkMonitoring",
    "OMSGallery/ADAssessment",
    "OMSGallery/ADReplication",
    "OMSGallery/AgentHealthAssessment",
    "OMSGallery/DnsAnalytics",
    "OMSGallery/KeyVaultAnalytics"
  ]
  publisher = "Microsoft"
}

# -----------------------------------------------------------------------------
# Landing Zone Key Vault
# -----------------------------------------------------------------------------

module "landing_zone_key_vault" {
  source              = "./.terraform/modules/landing-zone-1-0-0/key-vault"
  name                = replace(replace(module.landing_zone_resource_group.name, "-", ""), "_", "")
  resource_group_name = module.landing_zone_resource_group.name
  location            = module.landing_zone_resource_group.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  tags = merge(
    data.null_data_source.common_tags.outputs,
    map(
      "resource_type", "key vault"
    )
  )
}

# -----------------------------------------------------------------------------
# Landing Zone Storage Account
# -----------------------------------------------------------------------------

module "landing_zone_storage_account" {
  source              = "./.terraform/modules/landing-zone-1-0-0/storage/account"
  name                = var.storage_account_name
  resource_group_name = module.landing_zone_resource_group.name
  location            = module.landing_zone_resource_group.location
  account_tier        = "Standard"
  account_kind        = "StorageV2"

  tags = merge(
    data.null_data_source.common_tags.outputs,
    map(
      "resource_type", "storage account"
    )
  )
}

# -----------------------------------------------------------------------------
# Landing Zone Key Vault Monitor Diagnositc
# -----------------------------------------------------------------------------

module "lanzing_zone_key_vault_monitor_diagnositics" {
  source                     = "./.terraform/modules/landing-zone-1-0-0/monitor/diagnostic-setting"
  name                       = module.landing_zone_resource_group.name
  target_resource_id         = module.landing_zone_key_vault.id
  storage_account_id         = module.landing_zone_storage_account.id
  log_analytics_workspace_id = module.landing_zone_log_analytics_workspace.id
  log_category               = "AuditEvent"
  log_enabled                = true
  retention_policy_enabled   = true
  retention_policy_days      = 30
  metric_category            = "AllMetrics"
  metric_enabled             = true
}

# -----------------------------------------------------------------------------
# Landing Zone Storage Queue
# -----------------------------------------------------------------------------

module "landing_zone_storage_queue" {
  source               = "./.terraform/modules/landing-zone-1-0-0/storage/queue"
  names                = split(",", var.resource_group_name)
  storage_account_name = module.landing_zone_storage_account.name
}

# -----------------------------------------------------------------------------
# Landing Zone Event Subscription
# -----------------------------------------------------------------------------

module "landing_zone_event_grid" {
  source                = "./.terraform/modules/landing-zone-1-0-0/event-grid/event-subscription"
  name                  = module.landing_zone_resource_group.name
  scope                 = module.landing_zone_storage_account.id
  event_delivery_schema = "EventGridSchema"
  included_event_types = [
    "Blob Created"
  ]
  queue_name         = module.landing_zone_storage_queue.name[0]
  storage_account_id = module.landing_zone_storage_account.id
}
