# =============================================================================
# build/artifacts/container_platform.tf
# =============================================================================

###############################################################################
# Subnet allocation
###############################################################################

module "subnets" {
  source = "../modules/azure/subnet_allocator"

  vnet_name                = "ef74b0-dev-vwan-spoke"
  vnet_resource_group_name = "ef74b0-dev-networking"
  location                 = "canadacentral"

  subnets = [
    {
      name          = "mines-fabric-aci-snet"
      prefix_length = 27
      delegation = {
        name         = "aci-delegation"
        service_name = "Microsoft.ContainerInstance/containerGroups"
        actions      = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
      }
      nsg_rules = [
        {
          name                       = "AllowKeyVaultOutbound"
          priority                   = 200
          direction                  = "Outbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          destination_port_range     = "443"
          source_address_prefix      = "*"
          destination_address_prefix = "AzureKeyVault"
        },
        {
          name                       = "AllowVSCodeTunnelOutbound"
          priority                   = 210
          direction                  = "Outbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          destination_port_range     = "443"
          source_address_prefix      = "*"
          destination_address_prefix = "Internet"
        },
        {
          name                       = "AllowACIExecInbound"
          priority                   = 200
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          destination_port_range     = "19390"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
      ]
    }
  ]

}

###############################################################################
# ACR
###############################################################################

module "acr_01" {
  source = "../modules/azure/acr"

  prefix          = "mines"
  project         = "fabric"
  suffix          = "acr"
  instance_number = "01"

  resource_group_name = module.resource_group_adf.rg_name
  location            = "canadacentral"

  sku                           = "Premium"
  admin_enabled                 = true
  public_network_access_enabled = false
  zone_redundancy_enabled       = false

  identity_type = "SystemAssigned"

  private_endpoint_enabled   = false
  ip_rules                   = []

  enable_rbac_assignments    = true
  additional_access_policies = []


  depends_on = [module.resource_group_adf]
}

###############################################################################
# ACI Jumpbox
#
# Plain azure-cli container for on-demand exec access inside the VNet.
#   az container exec \
#     --subscription 53205a1b-0f8d-459e-a424-65f1b39ec648 \
#     --resource-group mines-fabric-rg02 \
#     --name mines-fabric-aci01 \
#     --container-name jumpbox \
#     --exec-command "/bin/bash"
###############################################################################

module "aci_jumpbox_01" {
  source = "../modules/azure/aci"

  prefix          = "mines"
  project         = "fabric"
  suffix          = "aci"
  instance_number = "01"

  resource_group_name = module.resource_group_adf.rg_name
  location            = "canadacentral"

  vnet_mode = true
  subnet_id = module.subnets.subnet_ids["mines-fabric-aci-snet"]

  acr_id           = module.acr_01.acr_id
  acr_login_server = module.acr_01.acr_login_server
  acr_username     = module.acr_01.acr_admin_username
  acr_password     = module.acr_01.acr_admin_password

  key_vault_id = module.key_vault_adf.kv_id

  enable_rbac_assignments = true
  create_managed_identity = true

  container_name    = "jumpbox"
  container_image   = "mcr.microsoft.com/azure-cli:latest"
  container_command = ["/bin/sh", "-c", "tail -f /dev/null"]
  cpu               = 1
  memory            = 1.5
  restart_policy    = "Always"

  environment_variables = {
    KEY_VAULT_URI = module.key_vault_adf.kv_dns_uri
    ACR_NAME      = module.acr_01.acr_name
    ENVIRONMENT   = var.ENVIRONMENT
  }


  depends_on = [
    module.resource_group_adf,
    module.key_vault_adf,
    module.acr_01,
    module.subnets,
  ]
}

###############################################################################
# VS Code Tunnel Jumpbox
#
# Single ACI container with VS Code Remote Tunnel.
# Connect from VS Code or browser — no public IP, no inbound ports.
# Authenticate interactively once connected via az login --use-device-code.
###############################################################################

module "vscode_tunnel" {
  source = "../modules/azure/vscode_tunnel"

  prefix          = "mines"
  project         = "fabric"
  instance_number = "01"
  resource_group_name = module.resource_group_adf.rg_name
  location            = "canadacentral"
  subnet_id   = module.subnets.subnet_ids["mines-fabric-aci-snet"]
  tunnel_name = "mines-jumpbox"

  key_vault_uri = module.key_vault_adf.kv_dns_uri
  environment   = var.ENVIRONMENT

  cpu    = 1
  memory = 2

  # No ARM credentials injected — once connected via the tunnel, authenticate
  # interactively with device code auth (works because the tunnel gives you
  # a browser):
  #   az login --use-device-code
  #   az account set --subscription 53205a1b-0f8d-459e-a424-65f1b39ec648
  secure_environment_variables = {}


  depends_on = [
    module.resource_group_adf,
    module.key_vault_adf,
    module.subnets,
  ]
}
