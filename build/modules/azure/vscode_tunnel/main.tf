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
    # Ubuntu 22.04 from MCR — has full glibc required by cli-linux-x64.
    # azure-cli image is CBL-Mariner (musl-based) and cannot run glibc binaries.
    image  = "mcr.microsoft.com/mirror/docker/library/ubuntu:22.04"
    cpu    = var.cpu
    memory = var.memory

    ports {
      port     = 443
      protocol = "TCP"
    }

    # cli-linux-x64 requires glibc — Ubuntu 22.04 provides this.
    # curl pre-installed on ubuntu:22.04, mv to /usr/bin avoids noexec on /tmp.
    commands = [
      "/bin/bash", "-c",
      "apt-get update -qq && apt-get install -y -qq curl ca-certificates gnupg lsb-release && curl -sL https://aka.ms/InstallAzureCLIDeb | bash && curl -Lk 'https://update.code.visualstudio.com/latest/cli-linux-x64/stable' -o /tmp/vscode.tar.gz && tar -xf /tmp/vscode.tar.gz -C /tmp && mv /tmp/code /usr/bin/code && chmod +x /usr/bin/code && VSCODE_CLI_DISABLE_KEYCHAIN_ENCRYPT=1 /usr/bin/code tunnel --accept-server-license-terms --name $TUNNEL_NAME"
    ]

    environment_variables = merge(
      {
        TUNNEL_NAME                    = var.tunnel_name
        KEY_VAULT_URI                  = var.key_vault_uri
        ENVIRONMENT                    = var.environment
        VSCODE_CLI_DISABLE_KEYCHAIN_ENCRYPT = "1"
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
