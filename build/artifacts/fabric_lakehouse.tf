module "fabric_lakehouse" {
  source = "../modules/azure/fabric_lakehouse"

  providers = {
    fabric.auth = fabric.auth
  }

  prefix          = "mines"
  project         = "fabric"
  instance_number = 1
  workspace_id    = module.fabric_workspace.workspace_id
  enable_schemas  = true
  schemas         = ["bronze", "silver", "gold"]
}