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
    image  = "mcr.microsoft.com/azure-cli:latest"
    cpu    = var.cpu
    memory = var.memory

    ports {
      port     = 443
      protocol = "TCP"
    }

    commands = [
      "/bin/sh",
      "-c",
      <<-EOT
        set -e

        echo "Installing required packages..."
        tdnf install -y curl tar gzip ca-certificates || true
        apt-get update -qq && apt-get install -y -qq curl tar gzip ca-certificates || true
        apk add --no-cache curl tar gzip ca-certificates libstdc++ || true

        echo "Downloading VS Code CLI..."
        curl -L 'https://code.visualstudio.com/sha/download?build=stable&os=cli-linux-x64' -o /tmp/vscode.tar.gz

        echo "Extracting VS Code CLI..."
        mkdir -p /tmp/vscode
        tar -xzf /tmp/vscode.tar.gz -C /tmp/vscode
        chmod +x /tmp/vscode/code

        echo "Starting VS Code tunnel..."
        export VSCODE_CLI_DISABLE_KEYCHAIN_ENCRYPT=1

        /tmp/vscode/code tunnel \
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