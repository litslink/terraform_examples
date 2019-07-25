resource "aws_s3_bucket" "alb_access_logs" {
  bucket        = "${var.env}-${var.project_name}-alb-access-logs"
  acl           = "private"
  force_destroy = true

  lifecycle_rule {
    id                                     = "cleanup"
    enabled                                = true
    abort_incomplete_multipart_upload_days = 1
    prefix                                 = "/"

    expiration {
      days = 3
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}


resource "aws_s3_bucket_policy" "lb_access_logs" {
  bucket = "${aws_s3_bucket.alb_access_logs.id}"

  policy = <<POLICY
{
  "Id": "Policy",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.alb_access_logs.arn}",
        "${aws_s3_bucket.alb_access_logs.arn}/*"
      ],
      "Principal": {
        "AWS": [ "${data.aws_elb_service_account.ecs.arn}" ]
      }
    }
  ]
}
POLICY
}
