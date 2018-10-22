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
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "${var.fargate_cpu}"
  memory                   = "${var.fargate_memory}"
  execution_role_arn       = "${aws_iam_role.ecs_tasks_role.arn}"


  container_definitions = <<DEFINITION
[
  {
    "name": "${var.app_container_name}",
    "image": "nginx",
    "cpu": ${var.fargate_cpu},
    "memory": ${var.fargate_memory},
    "networkMode": "awsvpc",
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
        "hostPort": ${var.app_container_port}
      }
    ]
  }
]
  DEFINITION

  lifecycle {
    create_before_destroy = true
  }

}


/* ECR Respository */
resource "aws_ecr_repository" "app" {
  name = "${var.env}-${var.project_name}"
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
    name = "${aws_alb.ecr_alb.dns_name}"
    zone_id = "${aws_alb.ecr_alb.zone_id}"
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