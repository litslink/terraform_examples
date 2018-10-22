provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
//  shared_credentials_file = "${var.shared_credentials_file}"
//  profile = "${var.aws_credentials_profile}"
  region = "${var.aws_region}"
}
