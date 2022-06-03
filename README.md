### Servian: Tech Challenge

## Solution design and deployment diagram

![Blank diagram](https://user-images.githubusercontent.com/2060769/117240934-8f043880-ae4f-11eb-8b08-de0472bb130f.jpeg)

## Tools and services 


## How to run?

# Prerequisites

# Steps to run


1. Setup variables like project name, region name, availability zones, CIDR etc  correctly in terraform.tfvars file.
2. Setup your terraform credential using 
```
$ export AWS_ACCESS_KEY_ID="<YOUR_KEY_ID>"
$ export AWS_SECRET_ACCESS_KEY="<YOUR_SECRET>"
```
3. Run Terraform using 
```
terraform init
terraform apply
```
4. To delete created resources
```
terraform destroy
```

# Outputs

This script creates 

- 1 Private VPC
- 1 Public and 1 Private Subnet per avaialability zone
- 1 NAT Gateway
- 1 Internet Gateway
- 1 Elastic IP for the internet gateway

- Monitoring and Logs

## Improvements

# CI/CD Pipeline

# Enhancing security

# Monitoring, Logging and Alerts




