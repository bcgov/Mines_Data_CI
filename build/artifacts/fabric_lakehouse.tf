module "fabric_lakehouse_01" {
  source = "../modules/azure/fabric_lakehouse"

  providers = {
    fabric.auth = fabric.auth
  }
  env             = var.ENVIRONMENT
  prefix          = var.PREFIX
  project         = var.PROJECT
  instance_number = 01
  workspace_id    = module.fabric_workspace_01.workspace_id
  folder_id       = local.fabric_item_folder_ids["lakehouses"]
  enable_schemas  = true
}
