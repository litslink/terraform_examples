resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags {
    Name = "${var.env}-vpc-ecs-${var.project_name}"
  }
}

resource "aws_internet_gateway" "ecs_ig" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name = "${var.env}-ecs-${var.project_name}-ig"
  }
}


resource "aws_subnet" "ecs_sn" {
  count = 1
  cidr_block = "10.0.${count.index}.0/24"
  vpc_id = "${aws_vpc.vpc.id}"
  availability_zone = "${data.aws_availability_zones.all.names[count.index]}"

  tags {
    Name = "${var.env}-ecs-${var.project_name}-sn${count.index}"
  }
}

resource "aws_route_table" "ecs_rt" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.ecs_ig.id}"
  }

  tags {
    Name = "${var.env}-ecs-${var.project_name}-rt"
  }
}

resource "aws_route_table_association" "ecs_rta_sn" {
  route_table_id = "${aws_route_table.ecs_rt.id}"
  subnet_id = "${aws_subnet.ecs_sn.*.id[count.index]}"
}

resource "aws_security_group" "vpc_default_sg" {
  name = "${var.env}-vpc-${var.project_name}-default-sg"
  description = "Default VPC SG - ${var.env} Environment"
  vpc_id = "${aws_vpc.vpc.id}"

  ingress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.env}-vpc-${var.project_name}-default-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}
