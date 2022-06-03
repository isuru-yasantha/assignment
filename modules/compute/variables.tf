variable "project" {
  description = "The name of the project"
}

variable "environment" {
  description = "The deployment environment"
}

variable "region" {
    description = "AWS region"
}

variable "ecstaskexecution_iam_role_arn" {
    description = "ECS IAM role arn"
}

variable "private_subnets_id" {
    description = "private subnet ids"
}

variable "service_sg_id" {
    description = "ECS service security group id"
}

variable "target_group_arn" {
    description = "arn of the LB target group"
}

variable "imageurl" {
  description = "container image"
}

variable "rds-endpoint" {
  description = "RDS endpoint address"
}

variable "secretmanager-id" {
  description = "ARN of secret manager secret"
}