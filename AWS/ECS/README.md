# Terraform ECS with EC2/Fargate

A set of **Terraform** templates used as an example of deployment ***AWS*** infrastructure with ***ECS EC2/Fargate***.

## About AWS ECS

Amazon Elastic Container Service (Amazon ECS) is a highly scalable, fast, container management service that makes it easy to run, stop, and manage Docker containers on a cluster.
You can host your cluster on a serverless infrastructure that is managed by Amazon ECS by launching your services or tasks using the Fargate launch type.
For more control you can host your tasks on a cluster of Amazon Elastic Compute Cloud (Amazon EC2) instances that you manage by using the EC2 launch type.

## About this project
This repository contains Terraform configuration for **ECS** with **EC2** (`EC2` directory) & **ECS** with **Fargate** (`Fargate` directory).

Templates deploy via Terraform a default nginx docker image and set up required AWS services. For example: IAM, Load Balancer, VPC, CloudWatch (including Auto Scaling and Logs), Route53 and ACM. 

## Prerequisites

- Install `terraform`, to get started, visit [terraform.io](https://www.terraform.io/intro/getting-started/install.html).
- (Optional) Install `aws-cli`, to get started, visit [docs.aws.amazon.com](https://docs.aws.amazon.com/en_us/cli/latest/userguide/installing.html).

## Getting started

- Create an AWS IAM user with administrative access to: `ECS`, `ECR`, `RDS`, `EC2`, `ACM`, `Route53`, `ELB`, `CloudWatch` and `S3`.
- Download directory with template file.
- Edit the template "sample_variables.template" files and fill it with variables relevant to the environment you're preparing:


```bash
    # for the EC2:
    cp EC2/sample_variables.template EC2/variables.tf
```

```bash
    # for the Fargate:
    cp FARGATE/sample_variables.template FARGATE/variables.tf
```

- Edit `variables.tf` file.


## Usage
Typically, the base Terraform will only need to be run once, and then should only need changes but hardly ever.

Change the directory to the relevant environment you want to initialize ( `cd FARGATE` or `cd EC2` ).

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

You can find out more information if you will read the `README.md` file in the folder with template files.