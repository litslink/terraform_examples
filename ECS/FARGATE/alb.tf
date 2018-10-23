data "aws_elb_service_account" "ecs" {}

/* ALB */
resource "aws_alb" "ecr_alb" {
  name = "${var.env}-${var.project_name}"

  # launch lbs in public or private subnets based on "internal" variable
  internal        = "${var.alb_internal}"
  subnets         = ["${aws_subnet.ecs_public_sn.*.id}"]
  security_groups = ["${aws_security_group.alb_sg.id}"]

  access_logs {
    enabled = true
    bucket  = "${aws_s3_bucket.alb_access_logs.bucket}"
  }
}

resource "aws_alb_target_group" "ecr_alb_tg" {
  name                 = "${var.env}-${var.project_name}"
  port                 = "${var.alb_port}"
  protocol             = "HTTP"
  vpc_id               = "${aws_vpc.vpc.id}"
  target_type          = "ip"
  deregistration_delay = "${var.dereg_delay}"

  health_check {
    matcher             = "${var.health_check_matcher}"
    interval            = "${var.health_check_interval}"
    timeout             = "${var.health_check_timeout}"
    healthy_threshold   = 5
    unhealthy_threshold = 5
  }
}

output "lb_dns" {
  value = "${aws_alb.ecr_alb.dns_name}"
}

resource "aws_alb_listener" "http" {
  load_balancer_arn = "${aws_alb.ecr_alb.id}"
  port              = "${var.alb_port}"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.ecr_alb_tg.id}"
    type             = "forward"
  }
}

resource "aws_alb_listener" "https" {
  load_balancer_arn = "${aws_alb.ecr_alb.id}"
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = "${aws_acm_certificate.cert_app.arn}"

  default_action {
    target_group_arn = "${aws_alb_target_group.ecr_alb_tg.id}"
    type             = "forward"
  }
}


resource "aws_security_group" "alb_sg" {
  name = "${var.env}-elb-${var.project_name}-sg"
  description = "SG - ELB of ${var.project_name} - ${var.env} Environment"
  vpc_id = "${aws_vpc.vpc.id}"

  ingress {
    from_port = "${var.alb_port}"
    protocol = "tcp"
    to_port = "${var.alb_port}"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    protocol = "tcp"
    to_port = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.env}-alb-${var.project_name}-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}
