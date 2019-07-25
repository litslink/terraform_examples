
resource "aws_s3_bucket" "cdn" {
  provider      = "aws.bucket"
  bucket        = "${var.s3_bucket_name}"
  acl           = "private"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "cdn" {
  provider      = "aws.bucket"
  bucket        = "${aws_s3_bucket.cdn.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AddPerm",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${aws_iam_user.user.arn}"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.cdn.bucket}/*"
    },
    {
      "Sid": "1",
      "Effect": "Allow",
      "Principal": {
          "AWS": "${aws_iam_user.user.arn}"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.cdn.bucket}/*"
    },
    {
      "Sid": "2",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.cdn.bucket}/*"
    }
  ]
}
EOF
}
