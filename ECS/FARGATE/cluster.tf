
/*--------------------------------*/
/*-- General ECS Configurations --*/
/*--------------------------------*/

/* ECS Cluster */
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.env}-${var.ecs_cluster_name}"
}


/* ECS Service */
resource "aws_ecs_service" "ecs_service" {
  name            = "${var.env}-${var.project_name}-ecs-service"
  cluster         = "${aws_ecs_cluster.ecs_cluster.id}"
  task_definition = "${aws_ecs_task_definition.app.arn}"
  desired_count   = "${var.ecs_service_count}"
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = ["${aws_security_group.ecs_sg.id}"]
    subnets         = ["${aws_subnet.ecs_private_sn.*.id}"]
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.ecr_alb_tg.id}"
    container_name   = "${var.app_container_name}"
    container_port   = "${var.app_container_port}"
  }

  depends_on = [
    "aws_alb_listener.http",
    "aws_iam_role.ecs_role",
  ]
}

/* AWS AppAutoScaling */
resource "aws_appautoscaling_target" "ecs_scale_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  max_capacity       = "${var.ecs_autoscale_max}"
  min_capacity       = "${var.ecs_autoscale_min}"
}

/* AWS Security Group */
resource "aws_security_group" "ecs_sg" {
  name = "${var.env}-${var.ecs_cluster_name}-sg"
  description = "Cluster SG - ${var.env} Environment - ${var.project_name}"
  vpc_id = "${aws_vpc.vpc.id}"

  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    security_groups = ["${aws_security_group.alb_sg.id}"]
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.env}-${var.ecs_cluster_name}-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

/*-----------------------*/
/*-- Cloud Watch --*/
/*-----------------------*/

/* Log group */

resource "aws_cloudwatch_log_group" "awslogs" {
  name = "${var.aws_cloudwatch_log_group}"
  retention_in_days = 7
}