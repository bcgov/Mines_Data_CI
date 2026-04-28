module "fabric_warehouse" {
  source = "../modules/azure/fabric_warehouse"

  providers = {
    fabric.auth = fabric.auth
  }
  prefix          = "mines"
  project         = "data-platform"
  instance_number = 01
  workspace_id    = module.fabric_workspace.workspace_id
}