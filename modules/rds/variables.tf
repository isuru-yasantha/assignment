variable "project" {
  description = "The name of the project"
}

variable "environment" {
  description = "The deployment environment"
}

variable "db_password" {
  description = "RDS root user password"
}

variable "db_username" {
  description = "RDS root username"
}

variable "db_name" {
  description = "DB creating in the RDS instance"
}

variable "db_instancetype" {
  description = "RDS instace type"
}

variable "db_storagesize" {
  description = "RDS instace type"
}

variable "rds_sg_id" {
  description = "RDS security group id"
}

variable "rds_db_subnetgroup_name" {
    description = "DB subnet group"
}