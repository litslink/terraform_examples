![terra_ecs](terra_ecs.png)
# Terraform ECS with AWS

A set of **Terraform** templates used as an example of deployment ***AWS*** infrastructure with ***ECS***, ***EKS*** and etc.


## About this project
This repository contains Terraform configuration for **ECS EC2/Fargate** (`ECS` directory).

Templates deploy via Terraform a default docker image and set up required AWS services.
For example: IAM, Load Balancer, VPC, CloudWatch (including Auto Scaling and Logs), Route53 and ACM. 

## Prerequisites

- Install `terraform`, to get started, visit [terraform.io](https://www.terraform.io/intro/getting-started/install.html).
- (Optional) Install `aws-cli`, to get started, visit [docs.aws.amazon.com](https://docs.aws.amazon.com/en_us/cli/latest/userguide/installing.html).

## Getting started

- Create an AWS IAM user with administrative access to: `ECS`, `ECR`, `RDS`, `EC2`, `ACM`, `Route53`, `ELB`, `CloudWatch` and `S3`.
- Download directory with template file.

## Usage
Typically, the base Terraform will only need to be run once, and then should only need changes but hardly ever.

Change the directory to the relevant environment you want to initialize.

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

##Additional Information
You can find out more information if you will read the `README.md` in project's folder.

- Total [README.md](ECS/README.md) for ECS templates.
    - [README.md](ECS/FARGATE/README.md) for ECS with Fargate.
    - [README.md](ECS/EC2/README.md) for ECS with EC2.
