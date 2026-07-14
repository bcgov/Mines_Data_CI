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
  enable_schemas  = true
}
