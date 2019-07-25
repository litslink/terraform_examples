# Terraform - Static site on S3 with CloudFront
Terraform template for create S3 Bucket for static hosting with CloudFront

## This template will create next:

`S3 Bucket` for static site
`CloudFront` for distribution
`DNS Record` on Route 53 for static site
`Certificate` for DNS name
`IAM User` with full access to S3 bucket and access make CreateInvalidation in CloudFront



## Getting started
### Change `variables.tf` file

```
variable "s3_region" {
  default     = "eu-central-1" <-- AWS region for S3 Bucket
}

variable "zone_id" {
  default = "XXXXXXXXXXXXX" <-- Zone ID for your domain in Route53
}

variable "domain_name" {
  default = "artem-s3.devlits.com" <-- Domain name for CNAME to CloudFront. Domain must be in your ID zone
}

variable "s3_bucket_name" {
  default     = "litslink-static-site" <-- S3 Bucket name
}

variable "iam_user" {
  default     = "litslink-static-site-iam" <-- AIM User name
}

```

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

## How update S3 content

```bash
# upload new data to S3
# region - if missmatch with default region
aws s3 sync my-new-site/ s3://S3_BUCKET_NAME --region AWS_REGION --delete

# make invalidation cache for CloudFront
aws cloudfront create-invalidation --distribution-id=DISTRIBUTION_ID --paths '/index.html'

```
