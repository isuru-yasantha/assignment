variable "project" {
  description = "The name of the project"
}

variable "environment" {
  description = "The deployment environment"
  default     = "dev"
}

variable "region" {
  description = "The AWS Region"
}

variable "availability_zones" {
  type        = list(any)
  description = "The names of the availability zones to use"
}

variable "vpc_cidr" {
  description = "The CIDR block of the vpc"
}

variable "public_subnets_cidr" {
  type        = list(any)
  description = "The CIDR block for the public subnet"
}

variable "private_subnets_cidr" {
  type        = list(any)
  description = "The CIDR block for the private subnet"
}

variable "db_subnets_cidr" {
  type        = list(any)
  description = "The CIDR block for the db subnet"
}

variable "db_password" {
  description = "RDS root user password"
  type        = string
  sensitive   = true
  default = "ktAL0wqj9Ek"
}

variable "db_username" {
  description = "RDS root username"
  type        = string
  default = "dbadmin"
}

variable "db_name" {
  description = "DB creating in the RDS instance"
  type = string
  default = "app"
}

variable "db_instancetype" {
  description = "RDS instace type"
  type        = string
  default = "db.t2.micro"
}

variable "db_storagesize" {
  description = "RDS instace type"
  type        = number
  default = 5
}

variable "imageurl" {
  description = "container image"
  type        = string
  default = "servian/techchallengeapp:latest"
}