# artifacts/fabric_workspace.tf

module "fabric_workspace_01" {
  source = "../modules/azure/fabric_workspace"

  providers = {
    fabric.auth = fabric.auth
  }
  env             = var.ENVIRONMENT
  prefix          = "mines"
  project         = "data-platform"
  instance_number = "01"
  capacity_id     = "198C68F4-8402-45B9-8010-BDE58A729DDF"
  owners          = ["b0bf68e8-4e08-433c-8903-19b2fec4cc20"]
  identity_type   = "SystemAssigned"
}
