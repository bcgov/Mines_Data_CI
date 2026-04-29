module "fabric_data_factory_01" {
  source = "../modules/azure/fabric_datafactory"

  providers = {
    fabric.auth = fabric.auth
  }

  prefix          = "mines"
  project         = "fabric"
  instance_number = 1
  workspace_id    = module.fabric_workspace_01.workspace_id
  description     = "Fabric Data Factory pipeline for mines data platform"
}