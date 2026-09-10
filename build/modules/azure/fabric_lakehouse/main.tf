terraform {
  required_providers {
    fabric = {
      source                = "microsoft/fabric"
      version               = "1.10.0"
      configuration_aliases = [fabric.auth]
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0"
    }
  }
}

locals {
  lakehouse_name = substr(
    replace(
      replace(
        var.lakehouse_name != null ? var.lakehouse_name : "${var.prefix}-${var.project}-lh${var.instance_number}${var.env != "" ? "-${var.env}" : ""}",
        " ",
        ""
      ),
      "-",
      "_"
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


# ─────────────────────────────────────────────────────────────────────────────
# Medallion folders under Files/
#
# OneLake speaks the ADLS Gen2 API, so folders are created with a plain
# "PUT ...?resource=directory" against the lakehouse's Files area. There is no
# Fabric provider resource for this — folders are storage paths, not Fabric
# items.
#
# These are folders, not lakehouse schemas. Lakehouse schemas live under
# Tables/ and only appear when a table is written into them; the ingest
# pipelines write parquet files, so Files/ is where the medallion layout
# belongs. Default layout is Files/{bronze,silver,gold}.
#
# Idempotent: creating a directory that already exists returns 409 Conflict,
# which the script treats as success. The null_resource only re-runs when the
# lakehouse or the folder list changes.
# ─────────────────────────────────────────────────────────────────────────────

resource "null_resource" "files_folders" {
  count = length(var.file_folders) > 0 ? 1 : 0

  triggers = {
    lakehouse_id = fabric_lakehouse.this.id
    workspace_id = var.workspace_id
    folders      = join(",", var.file_folders)
  }

  provisioner "local-exec" {
    command     = "bash ${path.module}/create_folders.sh"
    interpreter = ["bash", "-c"]

    environment = {
      WORKSPACE_ID   = var.workspace_id
      LAKEHOUSE_ID   = fabric_lakehouse.this.id
      LAKEHOUSE_NAME = fabric_lakehouse.this.display_name
      FOLDERS        = join(",", var.file_folders)
    }
  }

  depends_on = [fabric_lakehouse.this]
}
