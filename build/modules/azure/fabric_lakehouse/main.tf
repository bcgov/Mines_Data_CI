terraform {
  required_providers {
    fabric = {
      source                = "microsoft/fabric"
      version               = "1.6.0"
      configuration_aliases = [fabric.auth]
    }
  }
}

data "azurerm_client_config" "current" {}

locals {
  lakehouse_name = substr(
    replace(
      var.lakehouse_name != null ? var.lakehouse_name : "${var.prefix}-${var.project}-lh${var.instance_number}",
      " ",
      ""
    ),
    0,
    30
  )
}

resource "fabric_lakehouse" "this" {
  provider     = fabric.auth
  display_name = local.lakehouse_name
  description  = var.description
  workspace_id = var.workspace_id

  # enable_schemas forces recreation if changed after creation — set once and leave
  configuration = var.enable_schemas ? {
    enable_schemas = true
  } : null

  timeouts = {
    create = var.timeouts.create
    read   = var.timeouts.read
    update = var.timeouts.update
    delete = var.timeouts.delete
  }
}

# Create schemas via Fabric REST API using Azure CLI token
# Only runs when enable_schemas = true and schemas are provided
resource "null_resource" "lakehouse_schemas" {
  for_each = var.enable_schemas ? toset(var.schemas) : toset([])

  depends_on = [fabric_lakehouse.this]

  triggers = {
    lakehouse_id = fabric_lakehouse.this.id
    schema_name  = each.value
  }


  provisioner "local-exec" {
    command = <<-EOT
      TOKEN=$(az account get-access-token \
        --resource https://api.fabric.microsoft.com \
        --query accessToken \
        --output tsv)

      STATUS=$(curl -s -o /dev/null -w "%%{http_code}" \
        -X POST \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"name": "${each.value}"}' \
        "https://api.fabric.microsoft.com/v1/workspaces/${var.workspace_id}/lakehouses/${fabric_lakehouse.this.id}/schemas")

      # 201 = created, 409 = already exists (idempotent)
      if [[ "$STATUS" == "201" || "$STATUS" == "409" ]]; then
        echo "Schema '${each.value}' OK (HTTP $STATUS)"
      else
        echo "ERROR: Failed to create schema '${each.value}' (HTTP $STATUS)"
        exit 1
      fi
    EOT
  }
}

