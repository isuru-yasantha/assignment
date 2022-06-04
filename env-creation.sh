#!/bin/bash

echo '=== Setting up environment ==='
echo '=== Configuring AWS CLI... ==='

read -p 'Please provide your AWS region:' awsregion 
read -p 'Please provide AWS Acess Key:' accesskey
read -p 'Please provide AWS Secret Key:' secretkey

# checking prerequites terraform and AWS CLI installation
aws configure list >> /dev/null
exit_value1=$(echo $?)
terraform -version >> /dev/null
exit_value2=$(echo $?)

if [ $exit_value1 -ne 0 ] || [ $exit_value2 -ne 0 ];
then
    echo "=== AWS CLI or Terraform not installed. Please install them and try again ==="
    exit 1
else 
# configuring AWS CLI
    directory='newconfig'
    mkdir $directory
    cp -r setup/* $directory/
    sed -i.back "s/x/$awsregion/g" "$directory/config"  >> /dev/null
    sed -i.back "s/key1/$accesskey/g" "$directory/credentials"  >> /dev/null
    sed -i.back "s/key2/$secretkey/g" "$directory/credentials"  >> /dev/null
    cp -r $directory/* ~/.aws/ 

    echo "=== AWS CLI is configured successfully..... ==="

    # Creating S3 bucket for terraform remote backend and attaching bucket policy 

    echo "=== Setting up AWS S3 Bucket for Terraform remote backend in your AWS region ==="
    read -p 'Please provide S3 bucket name:' s3bucketname
    read -p 'Please provide AWS Account ID: ' awsaccountid
    read -p 'Please provide your IAM username: ' awsiamusername


    echo "=== Creatiing S3 bucket - $s3bucketname using your IAM user-$awsiamusername and AWS account-$awsaccountid ... ==="

    sed -i.back "s/x/$awsiamusername/g" "$directory/policy.json"  >> /dev/null
    sed -i.back "s/ACCOUNT_ID/$awsaccountid/g" "$directory/policy.json"  >> /dev/null
    sed -i.back "s/BUCKET_NAME/$s3bucketname/g" "$directory/policy.json"  >> /dev/null

    aws s3api create-bucket --bucket $s3bucketname --region $awsregion
    aws s3api put-bucket-policy --bucket $s3bucketname --policy file://$directory/policy.json     

    echo "=== AWS S3 bucket is created successfully.....==="
    echo "=== Setting up deployment environment variables ==="
 
   echo "=== $s3bucketname and $awsregion will be used for the deployment ==="

      # Updating region and S3 bucket in main.tf

    sed -i.back "s/regionVariable/$awsregion/g" main.tf  >> /dev/null
    sed -i.back "s/bucketVariable/$s3bucketname/g" main.tf  >> /dev/null

    echo "=== Variables are updated successfully in terraform.tfvars and main.tf ==="

     # Exporting AWS keys

    export AWS_ACCESS_KEY_ID="$accesskey"
    export AWS_SECRET_ACCESS_KEY="$secretkey"

    echo "=== initializing the terraform ==="
    terraform init

    echo "=== Executing the terraform syntax validation ==="
    terraform validate

    echo "=== Applying terraform ==="
    terraform apply

fi