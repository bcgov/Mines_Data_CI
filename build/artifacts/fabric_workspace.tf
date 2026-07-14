# artifacts/fabric_workspace.tf

module "fabric_workspace_01" {
  source = "../modules/azure/fabric_workspace"
  providers = {
    fabric.auth = fabric.auth
  }
  env             = var.ENVIRONMENT
  prefix          = var.PREFIX
  project         = var.PROJECT
  instance_number = "01"
  capacity_id     = local.fabric_capacity_id
  owners          = var.WORKSPACE_OWNERS
  identity_type   = "SystemAssigned"
}
