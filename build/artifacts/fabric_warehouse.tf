module "fabric_warehouse" {
  source = "../modules/azure/fabric_warehouse"

  providers = {
    fabric.auth = fabric.auth
  }

  prefix       = "mines"
  project      = "fabric"
  instance_number = 1
  workspace_name = module.fabric_workspace.workspace_id
}