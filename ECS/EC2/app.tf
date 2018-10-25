/*------------------------*/
/*-- ECS Configurations --*/
/*------------------------*/

/* Task Definition */
data "aws_ecs_task_definition" "app" {
  task_definition = "${aws_ecs_task_definition.app.family}"
  depends_on = ["aws_ecs_task_definition.app"]
}

resource "aws_ecs_task_definition" "app" {
  family = "${var.env}-${var.project_name}"
  volume {
    name = "${var.env}-${var.project_name}-storage"
    host_path = "${var.env}-${var.project_name}-storage"
  }

  container_definitions = <<DEFINITION
[
  {
    "name": "${var.app_container_name}",
    "image": "nginx",
    "cpu": 1,
    "memory": 512,
    "essential": true,
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${var.aws_cloudwatch_log_group}",
        "awslogs-region": "${var.aws_region}",
        "awslogs-stream-prefix": "${var.project_name}"
      }
    },
    "portMappings": [
      {
        "containerPort": ${var.app_container_port},
        "hostPort": ${var.app_instance_port}
      }
    ],
    "mountPoints": [
      {
        "containerPath": "/usr/share/nginx/html/",
        "sourceVolume": "${var.env}-${var.project_name}-storage"
      }
    ]
  }
]
  DEFINITION

  lifecycle {
    create_before_destroy = true
  }

}

/* Service */
resource "aws_ecs_service" "app" {
  name = "${var.env}-${var.project_name}"
  cluster = "${aws_ecs_cluster.ecs_cluster.id}"
  task_definition = "${aws_ecs_task_definition.app.family}:${max("${aws_ecs_task_definition.app.revision}", "${data.aws_ecs_task_definition.app.revision}")}"
  iam_role = "${aws_iam_role.ecs_role.name}"

  desired_count = 1
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent = 100

  load_balancer {
    elb_name = "${aws_elb.elb_app.name}"
    container_port = "${var.app_container_port}"
    container_name = "${var.app_container_name}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

/* ECR Respository */
resource "aws_ecr_repository" "app" {
  name = "${var.env}-${var.project_name}"
}


/*------------------------*/
/*-- EC2 Configurations --*/
/*------------------------*/

/* ELB */
resource "aws_elb" "elb_app" {
  name = "${var.env}-elb-${var.project_name}"
  security_groups = ["${aws_security_group.elb_sg.id}"]
  subnets = [
    "${aws_subnet.ecs_sn.*.id}"
  ]

  "listener" {
    instance_port = "${var.app_instance_port}"
    instance_protocol = "HTTP"
    lb_port = 80
    lb_protocol = "HTTP"
  }

  "listener" {
    instance_port = "${var.app_instance_port}"
    instance_protocol = "HTTP"
    lb_port = 443
    lb_protocol = "HTTPS"
    ssl_certificate_id = "${aws_acm_certificate_validation.cert_app.certificate_arn}"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 5
    timeout = 10
    target = "TCP:${var.app_instance_port}"
    interval = 30
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "elb_sg" {
  name = "${var.env}-elb-${var.project_name}-sg"
  description = "SG - ELB of ${var.project_name} - ${var.env} Environment"
  vpc_id = "${aws_vpc.vpc.id}"

  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = "${var.app_instance_port}"
    protocol = "tcp"
    to_port = "${var.app_instance_port}"
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
    Name = "${var.env}-elb-${var.project_name}-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

/*----------------------------*/
/*-- Route53 Configurations --*/
/*----------------------------*/

/* Route 53 */
resource "aws_route53_record" "r53_app_subd" {
  name = "${var.sub_domain_name}"
  type = "A"
  zone_id = "${var.zone_id}"

  alias {
    evaluate_target_health = true
    name = "${aws_elb.elb_app.dns_name}"
    zone_id = "${aws_elb.elb_app.zone_id}"
  }
}

resource "aws_route53_record" "cert_validation_app" {
  name = "${aws_acm_certificate.cert_app.domain_validation_options.0.resource_record_name}"
  type = "${aws_acm_certificate.cert_app.domain_validation_options.0.resource_record_type}"
  zone_id = "${var.zone_id}"
  records = ["${aws_acm_certificate.cert_app.domain_validation_options.0.resource_record_value}"]
  ttl = 60
}

/*----------------------------*/
/*-- Certificate Manager --*/
/*----------------------------*/

resource "aws_acm_certificate" "cert_app" {
  domain_name = "${var.sub_domain_name}${var.domain_name}"
  validation_method = "DNS"
}

resource "aws_acm_certificate_validation" "cert_app" {
  certificate_arn = "${aws_acm_certificate.cert_app.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert_validation_app.fqdn}"]
}