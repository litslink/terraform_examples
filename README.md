# Data integration project infrastructure as code (IaC)

## About this project
This repository contains Terraform configuration for *QA* (`qa` directory) environments used for the Data integration Project.

## Prerequisites

- Install `terraform`, to get started, visit [terraform.io](https://www.terraform.io/intro/getting-started/install.html).

## Getting started

- Create an AWS IAM user with administrative access to: `ECS`, `ECR`, `RDS`, `EC2`, `ACM`, `Route53` and `S3`.

- Edit the template "sample_variables.template" files and fill it with variables relevant to the environment you're preparing:


```bash
    # for the qa environment :
    cp qa/sample_variables.template qa/variables.tf
```

- Edit `variables.tf` file.

## Environment initialization
Change the directory to the relevant environment you want to initialize ( `cd qa` ).

Run the destroy command - (the command will not just stop but completely remove the infrastructure used for this environment)
```bash
    # The first command only for initializing (only if didn't start before)
    terraform init

    # to show changes list
    terraform plan

    # to apply the changes
    terraform apply
```

## Stopping(destroying) an environment
Change the directory to the relevant environment you want to initialize ( `cd qa` ).

**Warning** ! the command will not just stop but completely remove the infrastructure used for this environment :

```bash
    # Run the destroy command
    terraform destroy
```
