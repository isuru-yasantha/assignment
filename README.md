# Servian: Tech Challenge

## Solution design and deployment diagram

![Blank diagram](https://user-images.githubusercontent.com/2060769/117240934-8f043880-ae4f-11eb-8b08-de0472bb130f.jpeg)

## Tools and services 

- Terraform 
- GitHub
- AWS
 - AWS VPC
 - AWS ECS
 - AWS EC2 (ALB)
 - AWS S3
 - AWS IAM
 - AWS Secret Manager
 - AWS RDS
 - AWS CloudWatch

 Above mentioned AWS services are selected to design and deploy this application considering complexity to design, implement and operational overhead. Basic security is implemented for this solution at this stage. However, there are things that we can implement for enhance security, performance and cost saving aspects which discuss under improvement section.

 AWS VPC -  Network segmentation and virtual network isolation. MZ and DMZ are implemented. 
 AWS ECS - ECS with fargate is low cost, less complex solution to run containerized applications without putting much effort to maintain. Compute resources are provisioned and scaling based on resource requirement which help to reduce the infrastructure cost. 
 AWS EC2 (ALB) - ALB is used to front the public traffic to the application. 
 AWS S3 - S3 is used to store and maintain Terraform state file.
 AWS IAM - IAM role is used to grant access to AWS resources and AWS services via AWS API calls.
 AWS SecretManager - Secret Manager is used to store and maintain database user password which is referred by the application.
 AWS RDS - RDS is used for HA enabled database instance (Multi AZ).
 AWS Cloudwatch - Cloudwatch is used to handling monitoring metrics, logs and alarms. 

## How to run?

Please use below mentioned steps to deploy cloud infrasture to deploy this solution once you met the prerequisites mentioned below.

### Prerequisites

1. Terraform (Tested version for this solution - Terraform v1.0.11)
2. AWS IAM user keys with AWS Admin permission.
3. AWS S3 bucket with below access policy to grant access to above mentioned IAM user.
4. Web Brower (Tested with Google Chrome)

### Steps to run

1. Clone the GitHub repo
2. Provide executable permissions to the env-creation.sh 
```chmod +x env-creation.sh```
3. Run following command. 
```./env-creation.sh```

4. Provide required details by the script and follow the steps mentioned in the script to run the environment build. 

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
4. Please use env-deletion.sh to destroy the created resource. Please provide executable permission to env-deletion.sh before run the script.
```chmod +x env-deletion.sh```
```./env-deletion.sh```

```
terraform destroy
```

### Outputs

This Terraform script creates below resources, 

- 1 Private VPC
- 2 Public and 4 Private Subnets in two avaialability zones
- 2 NAT Gateways
- 1 Internet Gateway
- 1 Elastic IP for the internet gateway and 2 Elastic IPs for the NAT Gateways
- Route Tables and Security Groups
- IAM Role
- ALB and Target group
- ECS cluster
- RDS instance
- Secret Manager entry

After succesful execution of the script, you will be getting ALB DNS endpoint as an output. Please use the output DNS entry to access the web appliaction using a browser. 

```Ex: alb_endpoint = "testapp-dev-alb-101191681.us-east-1.elb.amazonaws.com"```

## Improvements

 - Security enhancements -
    #### Data at rest:

    AWS KMS key based encryption for AWS S3, AWS RDS and AWS Secret Manager

    #### Data at transit:

    Enabling HTTPS listener at ALB and secure with TLS certificate using AWS ACM for the public traffic. 
    Enabling HTTPS communication between app and RDS if app is supporting for establishing the HTTPS DB connection. 

    #### Network Security

    Enabling AWS Shield for DDOS protection
    Adding AWS Network ACL Rules for subnet traffic management
    Enabling AWS GuardDuty for sending alerts based on suspecious behaviours

    #### Web application Security

    Enable AWS WAF for ALB in order to protect from web based attacks
    Enable traffic to ALB only from AWS CDN
    Maintaning public domain name with Route53 and certificate via ACM

    #### Auditing

    Enabling access logs, auth logs, general logs on AWS ALB,AWS RDS, AWS ECS, AWS S3, AWS Secret Manager if available
    Enabling AWS Cloudtrails in the AWS region that the AWS resources provisioned
    Enabling metric based and log based AWS Cloudwatch alarms and sending notification via AWS SNS to stake holders

    ### Database

    Creating separate DB user and grant access only particular DB for that user in order to connect to the DB from the application

- Performance enhancements - 

    - Implementing a CDN to provide webapplication to the endusers
    - Implementing cloudwatch based alarms related to the scaling activities in ECS, error code based alarms for ALB, target group based alarms for unhealthy targets, RDS based alarms for critical metrics such as cpu,memory and storage
    - Implementing 3rd party health check or uptime monitor for the website
    - Implementing ECR for managing internal docker images

- Backups - 

    Enabling backups for AWS RDS, lifecycle policy for AWS S3 storage, log retention policy for AWS Cloudwatch logs
    Implementing remote managing of TF state using Dynamo DB based solution


- Cost savings
    Analyze the traffic patterns and resource utilisation metrics to come up with a better resource sizes. 

- Other -

   Runing AWS trusted advisor to get recommendations related to cost,performance and security to achive best from those aspects and implement them after analyzing the AWS recommendations according to the application requirements. 




### CI/CD Pipeline

- Stratergy - diagram
- tools and tech
- build failures and deployment failures 
- testing part of build
- CI and CD parts (CI -> getting base image from ECR)
- Roll back configurations based on alarms/deployment failures
- enable SNS topic based event alerts regarding the deployment process (fail,stop,rollback and done)
- 20% for 15min (based on requirement)
- use code pipeline for integrate both CB and CD parts
- code pipeline configure with github web hook to start the pipeline with source repo and branch

### Monitoring, Logging and Alerts

#### Infrastructure Monitoring  

Enabling AWS ingrastructure monitoring is highly important. This can be achived using AWS native solution using AWS Cloudwatch and AWS SNS.

#### Web application Monitoring  

Application metrics can be monitored using publishing custom metrics to AWS Cloudwatch using custom developed scripts. If not, 3rd party monitoring tool can be utilised to achive this. 

#### Endpoint Monitoring  

Internal endpoints such as backends can be monitored using AWS cloudwatch. However, recommending to use 3rd party monitoring tool to monitor public endpoints and application health check flow without depending on one tool. 