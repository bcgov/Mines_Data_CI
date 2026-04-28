module "fabric_capacity" {
  source              = "../modules/azure/fabric_rm_capacity"
  prefix              = "mines"
  suffix              = var.ENVIRONMENT
  project             = "fabric"
  Instance_Number     = "01"
  location            = "canadacentral"
  resource_group_name = module.resource_group.rg_name
  Owners              = ["b0bf68e8-4e08-433c-8903-19b2fec4cc20"]
  depends_on          = [module.resource_group_mines]
}