module "fabws_workspace_demo" {
  source = "../modules/azure/fabric_workspace/"
  providers = {
    fabric.auth = fabric.auth
  }
  project                     = "demo"
  prefix                      = "nr"
  instance_number             = 1
  description                 = "terraform demo workspace"
  capacity_id                 = "ad3cc06c-0f17-4432-b2aa-b402cf07fc05"
  identity_type               = "SystemAssigned"
  enable_git_integration      = false
  git_initialization_strategy = null
  git_provider_details        = null
  timeouts                    = {}
  timeouts_git                = {}
  owners                      = ["354120dd-2d06-4709-812a-0aca57f5f9fe"]
}

