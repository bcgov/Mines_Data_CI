# =============================================================================
# build/artifacts/variables.tf
#
# Single source of truth for every input used by the artifact layer.
# Values are supplied per environment through GitHub Environment variables
# (dev / test / prod) exported as TF_VAR_* in the workflows. Anything not
# supplied falls back to the defaults below, which reflect THIS branch's
# environment (test).
# =============================================================================

# ── Authentication (from GitHub Environment vars/secrets) ────────────────────

variable "ARM_TENANT_ID" {
  description = "Azure Tenant ID"
  type        = string
  default     = null
}

variable "ARM_CLIENT_ID" {
  description = "Azure Client ID"
  type        = string
}

variable "ARM_CLIENT_SECRET" {
  description = "Azure Client Secret"
  type        = string
  sensitive   = true
}

variable "ARM_SUBSCRIPTION_ID" {
  description = "Azure Subscription ID"
  type        = string
  default     = null
}

variable "GITHUB_PAT" {
  description = "GitHub Personal Access Token with repo scope. Used by the vscode_tunnel container to register the self-hosted GitHub Actions runner at startup. Set via GitHub secret GITHUB_PAT."
  type        = string
  sensitive   = true
  default     = null
}

# ── Environment ──────────────────────────────────────────────────────────────

variable "ENVIRONMENT" {
  description = "Environment name (dev, test, prod). Injected by CI/CD as TF_VAR_ENVIRONMENT based on the target branch."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "prod"], var.ENVIRONMENT)
    error_message = "ENVIRONMENT must be one of: dev, test, prod."
  }
}

# ── Naming ───────────────────────────────────────────────────────────────────

variable "PREFIX" {
  description = "Ministry/organization prefix used in all resource names."
  type        = string
  default     = "mcm"
}

variable "PROJECT" {
  description = "Project short name used in all resource names. Do NOT embed the environment here — modules append it as a suffix."
  type        = string
  default     = "mdp"
}

variable "LOCATION" {
  description = "Azure region for regional resources."
  type        = string
  default     = "canadacentral"
}

# ── Fabric capacity ──────────────────────────────────────────────────────────

variable "FABRIC_CAPACITY_NAME" {
  description = "Display name of the Fabric capacity. When set (recommended — set per environment via GitHub Environment variable FABRIC_CAPACITY_NAME), the capacity ID is resolved by name at plan time instead of hardcoding a GUID."
  type        = string
  default     = ""
}

variable "FABRIC_CAPACITY_ID" {
  description = "Fallback Fabric capacity GUID, used only when FABRIC_CAPACITY_NAME is empty."
  type        = string
  default     = "198C68F4-8402-45B9-8010-BDE58A729DDF"
}

# ── Access control ───────────────────────────────────────────────────────────

variable "WORKSPACE_OWNERS" {
  description = "Entra object IDs granted Admin on the Fabric workspace."
  type        = list(string)
  default = [
    "b0bf68e8-4e08-433c-8903-19b2fec4cc20",
    "ebb8207d-1ebe-423a-990d-82cf1e128cce",
    "e5922863-7748-46c8-9f50-bbc24834c2dd",
    "71a5bb67-14d7-40fe-8f3e-47120f2e32d3"
  ]
}

variable "GATEWAY_ADMINS" {
  description = "Entra object IDs granted Admin on the Fabric VNet data gateway."
  type        = list(string)
 default = ["b0bf68e8-4e08-433c-8903-19b2fec4cc20", "71a5bb67-14d7-40fe-8f3e-47120f2e32d3"]
}

variable "PURVIEW_ADMINS" {
  description = "Entra object IDs granted Root Collection Admin on the Purview account. Leave empty to reuse WORKSPACE_OWNERS — set this only when the two lists need to diverge."
  type        = list(string)
  default     = []
}

# ── Networking (Fabric VNet data gateway) ────────────────────────────────────

variable "VNET_NAME" {
  description = "Name of the existing spoke VNet hosting the gateway subnet. Leave null to derive from the environment (ef74b0-<env>-vwan-spoke)."
  type        = string
  default     = null
}

variable "VNET_RESOURCE_GROUP" {
  description = "Resource group of the existing spoke VNet. Leave null to derive from the environment (ef74b0-<env>-networking)."
  type        = string
  default     = null
}

variable "NETWORK_LICENSE_PLATE" {
  description = "BC Gov landing-zone license plate used when deriving default network names."
  type        = string
  default     = "ef74b0"
}

variable "REGISTER_POWERPLATFORM_RP" {
  description = "If true, register the Microsoft.PowerPlatform resource provider on the subscription. Required for the Fabric VNet data gateway to work. Set to false if already registered."
  type        = bool
  default     = false
}

# ── Purview ──────────────────────────────────────────────────────────────────

variable "PURVIEW_RESOURCE_GROUP_NAME" {
  description = "Resource group that holds the Purview account. Leave null to derive from the environment (ef74b0-<env>)."
  type        = string
  default     = "minesfabric-rg01"
}

variable "PURVIEW_PUBLIC_NETWORK_ENABLED" {
  description = "Whether the Purview account accepts public network traffic. Required by the Azure integration runtime used for Fabric scans; set to false only when moving to a managed VNet runtime."
  type        = bool
  default     = true
}

variable "PURVIEW_SCAN_ENABLED" {
  description = "If true, register the Fabric tenant as a Purview data source and configure the recurring scan. Set to false to deploy the account on its own — useful before the Fabric admin-portal prerequisites are in place."
  type        = bool
  default     = true
}

variable "PURVIEW_SCAN_SCOPE_TO_WORKSPACE" {
  description = "If true, scope the scan to the Fabric workspace created by this configuration. Set to false to scan every workspace in the tenant."
  type        = bool
  default     = true
}

variable "PURVIEW_RUN_SCAN_ON_APPLY" {
  description = "If true, start a scan run at the end of each apply instead of waiting for the first scheduled run."
  type        = bool
  default     = false
}