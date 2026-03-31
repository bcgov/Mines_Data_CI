module "fabric_gateway_minimal" {
  source = "../modules/azure/fabric_virtual_gateway"

  providers = {
    fabric.auth = fabric.auth
  }

  prefix      = "nr"
  project     = "fabric"
  capacity_id = "77e89824-a07e-42b8-b47f-2c68c13fb559"

  virtual_network_azure_resource = {
    subscription_id      = "ffc5e617-7f2d-4ddb-8b57-33fc43989a8c"
    resource_group_name  = "b9cee3-tools-networking"
    virtual_network_name = "b9cee3-tools-vwan-spoke"
    subnet_name          = "apim-subnet"
  }
}
