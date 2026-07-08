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
  owners          = ["b0bf68e8-4e08-433c-8903-19b2fec4cc20", "ebb8207d-1ebe-423a-990d-82cf1e128cce", "e5922863-7748-46c8-9f50-bbc24834c2dd", "71a5bb67-14d7-40fe-8f3e-47120f2e32d3"]
  identity_type   = "SystemAssigned"
}
