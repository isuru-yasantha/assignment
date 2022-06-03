variable "project" {
  description = "The name of the project"
}

variable "environment" {
  description = "The deployment environment"
}

variable "public_subnets_id" {
  description = "Public subnet ids"
}

variable "vpc_id" {
  description = "VPC id"
}

variable "alb_sg_id" {
  description = "ALB Security group id"
}