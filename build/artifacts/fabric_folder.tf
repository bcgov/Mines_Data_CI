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

data "fabric_folders" "existing" {
  provider     = fabric.auth
  workspace_id = module.fabric_workspace_01.workspace_id
  recursive    = false
}

locals {
  existing_fabric_folder_ids = {
    for folder in data.fabric_folders.existing.values :
    folder.display_name => folder.id
    if contains(local.fabric_item_folders, folder.display_name)
  }
}

resource "fabric_folder" "item_folders" {
  for_each = setsubtract(local.fabric_item_folders, toset(keys(local.existing_fabric_folder_ids)))

  display_name = each.key
  workspace_id = module.fabric_workspace_01.workspace_id
}

locals {
  fabric_item_folder_ids = merge(
    local.existing_fabric_folder_ids,
    { for name, folder in fabric_folder.item_folders : name => folder.id }
  )
}