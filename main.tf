//Setting Up AWS Provider
provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

//Kubernetes Provider
provider "kubernetes" {
}

//Importing AWS Module
module "aws_module" {
  source = "./aws"

  vpc_id = var.vpc
  db_user = var.db_user
  db_pass = var.db_pass
  db_name = var.database
}

//Importing Kubernetes Module
module "k8s_module" {
  source = "./kubernetes"

  db_host = module.aws_module.db_host
  db_user = var.db_user
  db_pass = var.db_pass
  db_name = var.database

  dependencies = [
    module.aws_module.db_host
  ]
}

//Open Wordpress Site
resource "null_resource" "open_wp" {
  provisioner "local-exec" {
    command = "start chrome 192.168.99.100:${module.k8s_module.wp_node_port}"
  }
}