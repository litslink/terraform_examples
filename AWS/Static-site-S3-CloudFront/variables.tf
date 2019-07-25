
//********************************* AWS *********************************//

variable "s3_region" {
  default     = "eu-central-1"
  description = "S3 bucket region"
}

## These variables are NOT needed if you use AWS CLI Profile ##

variable "aws_access_key" {
  default = ""
  description = "Access key for AWS"
}
variable "aws_secret_key" {
  default = ""
  description = "Secret key for AWS"
}

//******************************* Route 53 *******************************//

variable "zone_id" {
  default = "XXXXXXXXXXXXX"
  description = "Zone ID for your domain."
}

variable "domain_name" {
  default = "example.com"
  description = "Default domain. For example: example.com"
}

//***************************** S3 *****************************//

variable "s3_bucket_name" {
  default     = "terraform-static-site"
  description = "provide a name of s3 name"
}

## IAM user with full access to S3 and access CreateInvalidation to CloudFront

variable "iam_user" {
  default     = "terraform-static-site-iam"
  description = "provide a name of iam user"
}
