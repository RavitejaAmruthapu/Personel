terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "terraform-VPC"
  }
}
resource "aws_subnet" "subnet_pub" {
  vpc_id     = "${aws_vpc.vpc.id}"
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "terraform-subnet-public"
  }
}
resource "aws_subnet" "subnet_pvt" {
  vpc_id     = "${aws_vpc.vpc.id}"
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "terraform-subnet-private"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags = {
    Name = "terraform-igw"
  }
}
resource "aws_eip" "eip" {
  vpc      = true
}
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = "${aws_eip.eip.id}"
  subnet_id     = "${aws_subnet.subnet_pub.id}"

  tags = {
    Name = "terraform-NAT-GW"
  }
}

resource "aws_route_table" "rt_public" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags = {
    Name = "terraform-rt-public"
  }
}
resource "aws_route_table_association" "rt_association_pub" {
  subnet_id      = "${aws_subnet.subnet_pub.id}"
  route_table_id = "${aws_route_table.rt_public.id}"
}
resource "aws_route_table" "rt_pvt" {
  vpc_id = "${aws_vpc.vpc.id}"
  route {
    cidr_block = "10.0.1.0/24"
    gateway_id = "${aws_nat_gateway.nat_gw.id}"
  }
  tags = {
    Name = "terraform-rt-pvt"
  }
}
resource "aws_route_table_association" "rt_association_pvt" {
  subnet_id      = "${aws_subnet.subnet_pvt.id}"
  route_table_id = "${aws_route_table.rt_pvt.id}"
}

resource "aws_security_group" "sg_public" {
  name        = "terraform-sg-public"
  description = "erraform-sg-public"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "sg_pvt" {
  name        = "terraform-sg-private"
  description = "erraform-sg-private"
  vpc_id      = "${aws_vpc.vpc.id}"
  depends_on = [
    aws_security_group.sg_public,
  ]

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
	security_groups = [ "${aws_security_group.sg_public.id}" ]
  }  
}

resource "aws_instance" "ec2_public" {
  ami           = "ami-00b2d3ea9077fcebf" # ap-south-1
  instance_type = "t2.micro"
  key_name		= "AWS_Green"
  subnet_id		= "${aws_subnet.subnet_pub.id}"
  vpc_security_group_ids = ["${aws_security_group.sg_public.id}"]
  associate_public_ip_address = true
  source_dest_check = false
  tags = {
    Name = "terraform_ec2_pub"
  }
}
resource "aws_instance" "ec2_pvt" {
  ami           = "ami-00b2d3ea9077fcebf" # ap-south-1
  instance_type = "t2.micro"
  key_name		= "AWS_Green"
  subnet_id		= "${aws_subnet.subnet_pvt.id}"
  vpc_security_group_ids = ["${aws_security_group.sg_pvt.id}"]
  associate_public_ip_address = false
  source_dest_check = false
  tags = {
    Name = "terraform_ec2_pvt"
  }
}