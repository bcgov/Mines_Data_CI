# module "fabric_lakehouse" {
#   source = "../modules/azure/fabric_lakehouse"

#   providers = {
#     fabric.auth = fabric.auth
#   }

#   prefix          = "mines"
#   project         = "data-platform"
#   instance_number = 01
#   workspace_id    = module.fabric_workspace.workspace_id
#   enable_schemas  = true
#   schemas         = ["bronze", "silver", "gold"]
# }