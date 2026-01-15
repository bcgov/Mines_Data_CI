module "fabws_test41_i1_er" {
  source = "../modules/azure/fabric_workspace/"
  providers = {
    fabric.auth = fabric.auth
  }
  project                     = "fabric"
  prefix                      = "nr"
  instance_number             = 1
  description                 = "terraform test workspace"
  capacity_id                 = "77e89824-a07e-42b8-b47f-2c68c13fb559"
  identity_type               = "SystemAssigned"
  enable_git_integration      = false
  git_initialization_strategy = null
  git_provider_details        = null
  timeouts                    = {}
  timeouts_git                = {}
  owners                      = ["abigail.michel@gov.bc.ca","sebastian.hansen@gov.bc.ca"]
}

