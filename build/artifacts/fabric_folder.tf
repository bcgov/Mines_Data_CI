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
  # normalize a display name for comparison: lower-case and replace spaces with hyphens
  normalize = lambda(name) => lower(replace(name, " ", "-"))

  # map of normalized -> original desired folder name
  fabric_item_folders_normalized = {
    for name in local.fabric_item_folders : local.normalize(name) => name
  }

  # existing folders normalized -> id (only keep those that match desired normalized names)
  existing_fabric_folder_ids_normalized = {
    for folder in data.fabric_folders.existing.values : local.normalize(folder.display_name) => folder.id
    if contains(keys(local.fabric_item_folders_normalized), local.normalize(folder.display_name))
  }
}

resource "fabric_folder" "item_folders" {
  for_each = {
    for norm, orig in local.fabric_item_folders_normalized : norm => orig
    if !contains(keys(local.existing_fabric_folder_ids_normalized), norm)
  }

  display_name = each.value
  workspace_id = module.fabric_workspace_01.workspace_id
}

locals {
  # convert existing normalized map back to original-name -> id
  existing_fabric_folder_ids = {
    for norm, id in local.existing_fabric_folder_ids_normalized : local.fabric_item_folders_normalized[norm] => id
  }

  # newly created folders mapping original-name -> id
  created_fabric_folder_ids = {
    for norm, res in fabric_folder.item_folders : local.fabric_item_folders_normalized[norm] => res.id
  }

  fabric_item_folder_ids = merge(
    local.existing_fabric_folder_ids,
    local.created_fabric_folder_ids
  )
}