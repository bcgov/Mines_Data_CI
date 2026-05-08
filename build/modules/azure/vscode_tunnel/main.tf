terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.49.0"
    }
  }
}

locals {
  name = substr(
    replace(
      var.name != null ? var.name : "${var.prefix}-${var.project}-tunnel${var.instance_number}",
      " ", ""
    ),
    0, 63
  )
}

###############################################################################
# Container Group — VS Code Remote Tunnel
#
# Uses mcr.microsoft.com/azure-cli (MCR — accessible from your VNet).
# Downloads VS Code CLI at startup and runs the tunnel.
#
# FIRST-TIME AUTH (one time only):
#   az container logs \
#     --subscription 53205a1b-0f8d-459e-a424-65f1b39ec648 \
#     --resource-group <rg> --name <name> --container-name vscode-tunnel
#   Visit https://github.com/login/device and enter the code shown.
#   Tunnel is then live at: https://vscode.dev/tunnel/<tunnel_name>
#
# CONNECTING:
#   Browser  → https://vscode.dev/tunnel/<tunnel_name>
#   VS Code  → Remote - Tunnels extension → Connect to Tunnel → <tunnel_name>
#
# KEY VAULT (terminal inside VS Code once connected):
#   az login --use-device-code
#   az account set --subscription 53205a1b-0f8d-459e-a424-65f1b39ec648
#   az keyvault secret list --vault-name mines-fabric-kv01
#   az keyvault secret show  --vault-name mines-fabric-kv01 --name my-secret
#   az keyvault secret set   --vault-name mines-fabric-kv01 --name my-secret --value "value"
###############################################################################

resource "azurerm_container_group" "tunnel" {
  name                = local.name
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  restart_policy      = "Always"

  ip_address_type = "Private"
  subnet_ids      = [var.subnet_id]

  # Required by Azure when ip_address_type = "Private"
  exposed_port = [{
    port     = 443
    protocol = "TCP"
  }]

  container {
    name   = "vscode-tunnel"
    image  = "mcr.microsoft.com/azure-cli:latest"
    cpu    = var.cpu
    memory = var.memory

    ports {
      port     = 443
      protocol = "TCP"
    }

    # Downloads VS Code CLI at startup then starts the tunnel.
    commands = [
      "/bin/bash", "-c",
      "echo 'Starting VS Code tunnel setup...' && curl -sL 'https://code.visualstudio.com/sha/download?build=stable&os=cli-linux-x64' -o /tmp/vscode.tar.gz && echo 'Download complete' && tar -xf /tmp/vscode.tar.gz -C /usr/local/bin && chmod +x /usr/local/bin/code && echo 'Starting tunnel...' && code tunnel --accept-server-license-terms --name $TUNNEL_NAME"
    ]

    environment_variables = merge(
      {
        TUNNEL_NAME   = var.tunnel_name
        KEY_VAULT_URI = var.key_vault_uri
        ENVIRONMENT   = var.environment
      },
      var.extra_environment_variables
    )

    # No credentials injected — authenticate interactively once connected:
    #   az login --use-device-code
    #   az account set --subscription 53205a1b-0f8d-459e-a424-65f1b39ec648
    # Device code auth works because the tunnel gives you a browser.
    secure_environment_variables = var.secure_environment_variables
  }

  tags = var.tags
}
