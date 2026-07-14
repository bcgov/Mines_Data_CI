module "fabric_warehouse_01" {
  source = "../modules/azure/fabric_warehouse"

  providers = {
    fabric.auth = fabric.auth
  }
  prefix          = "mcm"
  project         = "mdp-${var.ENVIRONMENT}"
  instance_number = 01
  workspace_id    = module.fabric_workspace_01.workspace_id
}