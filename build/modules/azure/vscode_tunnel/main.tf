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
      " ",
      ""
    ),
    0,
    63
  )
}

resource "azurerm_container_group" "tunnel" {
  name                = local.name
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  restart_policy      = "Always"

  ip_address_type = "Private"
  subnet_ids      = [var.subnet_id]

  exposed_port = [{
    port     = 443
    protocol = "TCP"
  }]

  container {
    name   = "vscode-tunnel"
    image  = "ubuntu:22.04"
    cpu    = var.cpu
    memory = var.memory

    ports {
      port     = 443
      protocol = "TCP"
    }

    commands = [
      "/bin/bash",
      "-lc",
      <<-EOT
        set -Eeuo pipefail

        export DEBIAN_FRONTEND=noninteractive
        export VSCODE_CLI_DISABLE_KEYCHAIN_ENCRYPT=1

        echo "Installing base packages..."
        apt-get update -qq
        apt-get install -y -qq \
          ca-certificates \
          curl \
          tar \
          gzip \
          gnupg \
          lsb-release \
          apt-transport-https \
          libstdc++6

        echo "Installing Azure CLI..."
        mkdir -p /etc/apt/keyrings
        curl -sL https://packages.microsoft.com/keys/microsoft.asc \
          | gpg --dearmor \
          > /etc/apt/keyrings/microsoft.gpg

        chmod go+r /etc/apt/keyrings/microsoft.gpg

        AZ_DIST="$(lsb_release -cs)"
        echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $AZ_DIST main" \
          > /etc/apt/sources.list.d/azure-cli.list

        apt-get update -qq
        apt-get install -y -qq azure-cli

        echo "Downloading VS Code CLI..."
        mkdir -p /opt/vscode-cli
        curl -fL \
          "https://code.visualstudio.com/sha/download?build=stable&os=cli-linux-x64" \
          -o /tmp/vscode-cli.tar.gz

        echo "Extracting VS Code CLI..."
        tar -xzf /tmp/vscode-cli.tar.gz -C /opt/vscode-cli
        chmod +x /opt/vscode-cli/code

        echo "Azure CLI version:"
        az version --output table || true

        echo "Starting VS Code Remote Tunnel..."
        echo "Tunnel name: $TUNNEL_NAME"

        /opt/vscode-cli/code tunnel \
          --accept-server-license-terms \
          --name "$TUNNEL_NAME"
      EOT
    ]

    environment_variables = merge(
      {
        TUNNEL_NAME                         = var.tunnel_name
        KEY_VAULT_URI                       = var.key_vault_uri
        ENVIRONMENT                         = var.environment
        VSCODE_CLI_DISABLE_KEYCHAIN_ENCRYPT = "1"
      },
      var.extra_environment_variables
    )

    secure_environment_variables = var.secure_environment_variables
  }

  tags = var.tags
}