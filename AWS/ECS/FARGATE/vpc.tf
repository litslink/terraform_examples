
data "aws_availability_zones" "all" {}

resource "aws_vpc" "vpc" {
  cidr_block = "10.2.0.0/16"
  enable_dns_hostnames = true

  tags {
    Name = "${var.env}-vpc-ecs-${var.project_name}"
  }
}

resource "aws_subnet" "ecs_private_sn" {
  count             = "${var.ecs_autoscale_max}"
  cidr_block        = "${cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index)}"
  availability_zone = "${data.aws_availability_zones.all.names[count.index]}"
  vpc_id            = "${aws_vpc.vpc.id}"

  tags {
    Name = "${var.env}-ecs-${var.project_name}-private-sn${count.index}"
  }
}


resource "aws_subnet" "ecs_public_sn" {
  count                   = "${var.ecs_autoscale_max}"
  cidr_block              = "${cidrsubnet(aws_vpc.vpc.cidr_block, 8, var.ecs_service_count + count.index)}"
  availability_zone       = "${data.aws_availability_zones.all.names[count.index]}"
  vpc_id                  = "${aws_vpc.vpc.id}"
  map_public_ip_on_launch = true

  tags {
    Name = "${var.env}-ecs-${var.project_name}-public-sn${count.index}"
  }
}

resource "aws_internet_gateway" "ecs_ig" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name = "${var.env}-ecs-${var.project_name}-ig"
  }
}

resource "aws_eip" "ecs_gw" {
  count      = "${var.ecs_autoscale_max}"
  vpc        = true
  depends_on = ["aws_internet_gateway.ecs_ig"]
}

resource "aws_nat_gateway" "ecs_public_ng" {
  count         = "${var.ecs_service_count}"
  subnet_id     = "${element(aws_subnet.ecs_public_sn.*.id, count.index)}"
  allocation_id = "${element(aws_eip.ecs_gw.*.id, count.index)}"

  tags {
    Name = "${var.env}-ecs-${var.project_name}-public-ng${count.index}"
  }
}

resource "aws_route" "ecs_internet_access" {
  route_table_id         = "${aws_vpc.vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.ecs_ig.id}"
}

resource "aws_route_table" "ecs_private_rt" {
  count = "${var.ecs_autoscale_max}"
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.ecs_public_ng.*.id[count.index]}"
  }

  tags {
    Name = "${var.env}-ecs-${var.project_name}-rt"
  }
}

resource "aws_route_table_association" "ecs_private_rta" {
  count = "${var.ecs_autoscale_max}"
  route_table_id = "${aws_route_table.ecs_private_rt.*.id[count.index]}"
  subnet_id = "${aws_subnet.ecs_private_sn.*.id[count.index]}"
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
