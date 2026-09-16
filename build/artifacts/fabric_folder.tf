locals {
  fabric_item_folders = toset([
    "lakehouses",
    "notebooks",
    "pipelines",
    "reports",
    "semantic-models",
    "variable-libraries",
    "warehouses",
  ])
}

resource "fabric_folder" "item_folders" {
  provider = fabric.auth
  for_each = local.fabric_item_folders

  display_name = each.key
  workspace_id = module.fabric_workspace_01.workspace_id
}

locals {
  fabric_item_folder_ids = {
    for name, folder in fabric_folder.item_folders :
    name => folder.id
  }
}