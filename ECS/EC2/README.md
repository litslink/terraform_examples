# Terraform ECS with EC2
A set of **Terraform** templates used as an example of deployment ***AWS*** infrastructure with ***ECS EC2***.

## About this project
This repository contains Terraform configuration for **ECS** with **EC2** (`EC2` directory).

Templates deploy via Terraform a default nginx docker image and set up required AWS services. For example: IAM, Load Balancer, S3, VPC, CloudWatch (including Auto Scaling and Logs) and Route53 with ACM (add DNS records, create and validate certificate). 

## Prerequisites

- Install `terraform`, to get started, visit [terraform.io](https://www.terraform.io/intro/getting-started/install.html).
- (Optional) Install `aws-cli`, to get started, visit [docs.aws.amazon.com](https://docs.aws.amazon.com/en_us/cli/latest/userguide/installing.html).
## Getting started

- Create an AWS IAM user with administrative access to: `ECS`, `ECR`, `RDS`, `EC2`, `ACM`, `Route53` and `S3`.
- Download directory with template file.
- Edit the template "sample_variables.template" files and fill it with variables relevant to the environment you're preparing:


```bash
    # for the Fargate:
    cp EC2/sample_variables.template EC2/variables.tf
```

- Edit `variables.tf` file.

## Usage
Typically, the base Terraform will only need to be run once, and then should only need changes but hardly ever.

Change the directory to the relevant environment you want to initialize ( `cd EC2` ).

### Environment initialization
Run the *init* command.
```bash
    # The first command only for initializing (only if didn't start before)
    terraform init

```
### Start/change an environment
Run the *plan* or *apply* command.
```bash
    # to show changes list
    terraform plan

    # to apply the changes
    terraform apply
```

### Stopping(destroying) an environment
Run the *destroy* command.

**Warning!!!** the command will not just stop but completely remove the infrastructure used for this environment :

```bash
    # Run the destroy command
    terraform destroy
```

## Components

These components are for a specific environment. There should be a corresponding directory for each environment that is needed.

| Name | Description | Optional |
|------|-------------|:---:|
| [app.tf](app.tf) | ECS task definition, ECS service, ECR, ELB, Listener, SecurityGroup, Route53, ACM  | - |
| [cluster.tf](cluster.tf) | ECS cluster, EC2 configuration, CloudWatch, AutoScaling group, SecurityGroup | - |
| [iam.tf](iam.tf) | IAM role and policy | - |
| [main.tf](main.tf) | AWS provider | - |
| [sample_variables.template](sample_variables.template) | Template variable file  | - |
| [vpc.tf](vpc.tf) | VPC, Subnet, Internet Gateway, Route Table, Security Group  | - ||

## Variables

| Name | Description | Default | Required |
|------|-------------|:-------:|:--------:|
| app | The application's name | - | yes |
| app_container_name | The name of the container to run | app | yes |
| app_container_port | The port the container will listen on, used for load balancer health check Best practice is that this value is higher than 1024 so the container processes isn't running at root. | 80 | yes |
| app_instance_port | The port the load balancer will listen on | 8080 | no |
| aws_access_key | Like a user name and password, you must use both the access key ID and secret access key together to authenticate your requests. | - | yes |
| aws_cloudwatch_log_group | Default awslogs group name. You can use the name of the project or application | app | yes |
| aws_ec2_key_name | To log in to your instance, you must create a key pair, specify the name of the key pair when you launch the instance, and provide the private key when you connect to the instance | ec2_instance_ecs | yes |
| aws_region | The AWS region to use for the dev environment's infrastructure Currently, Fargate is only available in us-east-1. | us-east-1 | no |
| aws_secret_key | Like a user name and password, you must use both the access key ID and secret access key together to authenticate your requests. | - | yes |
| domain_name | That's root domain zone in route53 | - | yes |
| ecs_cluster_name | The cluster's name | cluster | no |
| image_id_default | Default ami image Amazone EC2 Linux. The current AMI IDs by region are listed here => (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html) | ami-0b9a214f40c38d5eb | no |
| instance_type | An Amazon ECS launch type determines the type of infrastructure on which your tasks and services are hosted. | t2.micro | no |
| env | The environment that is being built | qa | no |
| project_name | The project's name | app | no |
| sub_domain_name | Default sub-domain | nginx.qa. | no |
| vpc | The VPC to use for the Fargate cluster | vpc | yes |
| zone_id | Zone ID for your domain | - | yes ||
