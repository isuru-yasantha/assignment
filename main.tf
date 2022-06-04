terraform {

   backend "s3" {
    bucket = "bucketVariable"
    key = "tfstate/terraform.tfstate"
    region = "regionVariable"
}

}

provider "aws" {
  region = var.region
}

/* Networking Module */

module "networking" {
  source = "./modules/networking"

  project              = var.project
  environment          = var.environment
  region               = var.region
  availability_zones   = var.availability_zones
  vpc_cidr             = var.vpc_cidr
  public_subnets_cidr  = var.public_subnets_cidr
  private_subnets_cidr = var.private_subnets_cidr
  db_subnets_cidr      = var.db_subnets_cidr
}

/* IAM Module */

module "iam" {
  source = "./modules/iam"
  depends_on           = [module.secretmanager]
  project              = var.project
  environment          = var.environment
  secretmanager-id     = module.secretmanager.secretmanager-id
}

/* RDS Module */

module "rds" {
  source = "./modules/rds"
  depends_on = [module.networking]
  project              = var.project
  environment          = var.environment
  db_username          = var.db_username
  db_password          = var.db_password
  db_name              = var.db_name
  db_instancetype      = var.db_instancetype
  db_storagesize       = var.db_storagesize
  rds_sg_id            = module.networking.rds_sg_id
  rds_db_subnetgroup_name = module.networking.rds_db_subnetgroup_name
}

/* Compute Module */

module "compute" {
  source = "./modules/compute"
  depends_on = [module.networking,module.iam,module.rds,module.alb,module.secretmanager]
  project              = var.project
  environment          = var.environment
  region               = var.region
  imageurl             = var.imageurl
  ecstaskexecution_iam_role_arn = module.iam.ecstaskexecution_iam_role_arn
  service_sg_id        = module.networking.service_sg_id
  private_subnets_id   = module.networking.private_subnets_id
  target_group_arn     = module.alb.target_group_arn
  rds-endpoint         =  module.rds.rds-endpoint
  secretmanager-id     = module.secretmanager.secretmanager-id
}

/* LB Module */

module "alb" {
  source = "./modules/alb"
  depends_on = [module.networking]
  project              = var.project
  environment          = var.environment
  vpc_id               = module.networking.vpc_id
  public_subnets_id    = module.networking.public_subnets_id
  alb_sg_id            = module.networking.alb_sg_id
}

/* Secret Manager Module */

module "secretmanager" {
  source = "./modules/secretmanager"
  project              = var.project
  environment          = var.environment
  db_password          = var.db_password
}