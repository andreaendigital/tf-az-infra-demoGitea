# environments/demo/main.tf
module "resource_group" {
  source = "../../modules/resource-group"

  environment  = var.environment
  location     = var.location
  project_name = var.project_name
}

module "network" {
  source = "../../modules/network"

  resource_group_name     = module.resource_group.name
  location               = var.location
  environment            = var.environment
  network_security_group = module.network_security_group.id
}

module "jenkins_vm" {
  source = "../../modules/compute"

  resource_group_name = module.resource_group.name
  location           = var.location
  subnet_id          = module.network.subnet_id
  vm_name            = "vm-jenkins-${var.environment}"
}
