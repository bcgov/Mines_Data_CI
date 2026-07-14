module "fabric_lakehouse_01" {
  source = "../modules/azure/fabric_lakehouse"

  providers = {
    fabric.auth = fabric.auth
  }
  prefix          = "mcm"
  project         = "mdp-${var.ENVIRONMENT}"
  instance_number = 01
  workspace_id    = module.fabric_workspace_01.workspace_id
  enable_schemas  = true
}