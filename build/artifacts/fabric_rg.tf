# artifacts/main.tf

module "resource_group_mines" {
  source = "../modules/azures/resource_groups"

  prefix          = "mines"
  suffix          = "az"
  project         = "fabric"
  env             = var.ENVIRONMENT
  Instance_Number = "01"
  location        = "canadacentral"
}
