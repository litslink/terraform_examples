
/*--------------------------------*/
/*-- General ECS Configurations --*/
/*--------------------------------*/

/* ECS Cluster */
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.env}-${var.ecs_cluster_name}"
}

/*-----------------------*/
/*-- EC2 Configurations --*/
/*-----------------------*/

/* Launch Configuration */
resource "aws_launch_configuration" "instance_app" {
  name_prefix = "${var.env}-${var.project_name}"
  image_id = "${var.image_id_default}"
  instance_type = "${var.instance_type}"
  security_groups = ["${aws_security_group.ecs_sg.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.instance_profile.name}"
  key_name = "${var.aws_ec2_key_name}"

  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${var.env}-${var.ecs_cluster_name} >> /etc/ecs/ecs.config
    EOF

  lifecycle {
    create_before_destroy = true
  }
}


/* Auto Scalling Group */
resource "aws_autoscaling_group" "asg" {
  launch_configuration = "${aws_launch_configuration.instance_app.id}"
  vpc_zone_identifier = [
    "${aws_subnet.ecs_sn.*.id}"
  ]

  min_size = 1
  max_size = 3
  health_check_type = "ELB"

  load_balancers = ["${aws_elb.elb_app.id}"]

  tag {
    key = "Name"
    propagate_at_launch = true
    value = "${var.env}-${var.ecs_cluster_name}-${var.project_name}"
  }

  lifecycle {
    create_before_destroy = true
  }
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
    security_groups = ["${aws_security_group.elb_sg.id}"]
  }

  ingress {
    from_port = "${var.app_instance_port}"
    protocol = "tcp"
    to_port = "${var.app_instance_port}"
    security_groups = ["${aws_security_group.elb_sg.id}"]
  }

  ingress {
    from_port = 22
    protocol = "tcp"
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
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

data "aws_availability_zones" "all" {}