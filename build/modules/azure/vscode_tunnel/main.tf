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

    # Use Azure CLI image so az is already installed.
    # Avoid installing Azure CLI during container startup.
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
        set -eu

        echo "Container started."
        echo "Tunnel name: $TUNNEL_NAME"
        echo "Checking Azure CLI..."
        az version --output table || true

        echo "Installing minimal VS Code CLI dependencies..."
        if command -v tdnf >/dev/null 2>&1; then
          tdnf install -y curl tar gzip ca-certificates libstdc++ shadow-utils || true
        elif command -v apk >/dev/null 2>&1; then
          apk add --no-cache curl tar gzip ca-certificates libstdc++ || true
        elif command -v apt-get >/dev/null 2>&1; then
          export DEBIAN_FRONTEND=noninteractive
          apt-get update -qq
          apt-get install -y -qq curl tar gzip ca-certificates libstdc++6
        fi

        echo "Preparing VS Code CLI directory..."
        rm -rf /opt/vscode-cli /tmp/vscode-cli.tar.gz
        mkdir -p /opt/vscode-cli

        echo "Downloading VS Code CLI Linux x64..."
        curl -fL \
          "https://code.visualstudio.com/sha/download?build=stable&os=cli-linux-x64" \
          -o /tmp/vscode-cli.tar.gz

        echo "Extracting VS Code CLI..."
        tar -xzf /tmp/vscode-cli.tar.gz -C /opt/vscode-cli
        chmod +x /opt/vscode-cli/code

        echo "VS Code CLI version:"
        /opt/vscode-cli/code --version || true

        echo "Starting VS Code tunnel..."
        export VSCODE_CLI_DISABLE_KEYCHAIN_ENCRYPT=1

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