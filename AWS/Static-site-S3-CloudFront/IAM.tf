resource "aws_iam_user" "user" {
  name = "${var.iam_user}"
  path = "/system/"
}

resource "aws_iam_access_key" "user" {
  user = "${aws_iam_user.user.name}"
}

resource "aws_iam_user_policy" "s3" {
  name = "S3-FullAccess-${var.s3_bucket_name}"
  user = "${aws_iam_user.user.name}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "1",
            "Effect": "Allow",
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::arn:aws:s3:::${aws_s3_bucket.cdn.bucket}/*"
        },
        {
            "Sid": "2",
            "Effect": "Allow",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::/arn:aws:s3:::${aws_s3_bucket.cdn.bucket}/*"
        },
        {
            "Sid": "3",
            "Effect": "Allow",
            "Action": [
                "s3:PutAccountPublicAccessBlock",
                "s3:GetAccountPublicAccessBlock",
                "s3:ListAllMyBuckets",
                "s3:HeadBucket"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor3",
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::${aws_s3_bucket.cdn.bucket}/*",
                "arn:aws:s3:::${aws_s3_bucket.cdn.bucket}"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_user_policy" "cloudfront" {
  name = "CF-CreateInvalidation-${var.s3_bucket_name}"
  user = "${aws_iam_user.user.name}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:ListAllMyBuckets",
            "Resource": "arn:aws:s3:::${aws_s3_bucket.cdn.bucket}"
        },
        {
            "Action": [
                "cloudfront:CreateInvalidation",
                "cloudfront:GetDistribution",
                "cloudfront:GetStreamingDistribution",
                "cloudfront:GetDistributionConfig",
                "cloudfront:GetInvalidation",
                "cloudfront:ListInvalidations",
                "cloudfront:ListStreamingDistributions",
                "cloudfront:ListDistributions"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
EOF
}
